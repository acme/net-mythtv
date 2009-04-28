#!/home/acme/perl-5.10.0/bin/perl
use strict;
use warnings;
use Date::Manip;
use DateTime;
use DateTime::Format::ISO8601;
use DateTime::Format::Strptime;
use HTML::TreeBuilder;
use HTML::TreeBuilder::XPath;
use JSON::XS::VersionOneAndTwo;
use Lingua::EN::Numbers qw(num2en);
use List::Util qw(first);
use LWP::UserAgent;
use Perl6::Say;
use URI;
use URI::QueryParam;

my $host = 'http://owl.local';

# Thu Apr 30, 2009 (09:00 PM)
my $datetime_parser = DateTime::Format::Strptime->new(
    pattern  => '%a %b %d, %Y (%I:%M %p)',
    on_error => 'croak',
);

my $ua = LWP::UserAgent->new;
$ua->default_header( 'Accept-Language' => 'en' );

# <a title="Details for: BBC ONE" href="/mythweb/tv/channel/1001/1240863300">
my $list_response = $ua->get("$host/mythweb/tv/list");
die $list_response->status_line unless $list_response->is_success;

my $ltree = HTML::TreeBuilder::XPath->new;
$ltree->parse_content( $list_response->content );

my %channel_ids;
foreach my $child ( $ltree->findnodes('//a') ) {
    my $href = $child->attr('href');
    next unless $href;
    next unless $href =~ m{/mythweb/tv/channel/};

    my $url = URI->new( $host . $href );
    my ( undef, undef, undef, undef, $channel_id, $start_time ) = split '/',
        $url->path;

    my $text = $child->as_text;
    $text =~ s/^ +//;
    $text =~ s/^\d+ //;
    $text =~ s/ +$//;
    say "$channel_id $text";
    $channel_ids{$text} = $channel_id;
}

my $json_response
    = $ua->get('http://www.mightyv.com/feed/schedule/acme/json');
die $json_response->status_line unless $json_response->is_success;
my @events = @{ from_json( $json_response->content ) };
foreach my $event (@events) {
    my $start = DateTime::Format::ISO8601->parse_datetime( $event->{start} )->set_time_zone('UTC')
        ->set_time_zone('Europe/London');
    my $start_epoch = $start->epoch;
    my $channel          = $event->{name};
    my $matching_channel = first {
        my $a = lc $channel;
        $a =~ s/ //g;
        $a =~ s/(\d+)/num2en($1)/e;
        my $b = lc $_;
        $b =~ s/ //g;
        $b =~ s/(\d+)/num2en($1)/e;
        $a eq $b;
    }
    keys %channel_ids;
    my $channel_id = $channel_ids{$matching_channel};
    say $event->{start} . " $start $channel $matching_channel $channel_id $host/mythweb/tv/detail/$channel_id/$start_epoch";
}

exit;

my $response = $ua->get("$host/mythweb/tv/upcoming");
die $response->status_line unless $response->is_success;

my $ntree = HTML::TreeBuilder::XPath->new;
$ntree->parse_content( $response->content );

my ($table) = $ntree->findnodes('id("listings")');
foreach my $child ( $table->content_list ) {
    my $class = $child->attr('class');
    next unless $class eq 'scheduled';
    my @tds        = $child->content_list;
    my $title      = $tds[2]->as_text;
    my $airdate    = $tds[4]->as_text;
    my $airdate_dt = $datetime_parser->parse_datetime($airdate);
    my ($actions)  = $tds[6]->content_list;
    my $url        = URI->new( $host . $actions->attr('href') );
    die "Missing dontrec field" unless $url->query_param('dontrec') eq 'yes';
    my ( undef, undef, undef, undef, $channel_id, $start_time ) = split '/',
        $url->path;
    my $dt
        = DateTime->from_epoch( epoch => $start_time )->set_time_zone('UTC')
        ->set_time_zone('Europe/London');
    say "$title / $channel_id / $airdate_dt";
}


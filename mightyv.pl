#!/home/acme/perl-5.10.0/bin/perl
use strict;
use warnings;
use Date::Manip;
use DateTime;
use DateTime::Format::Strptime;
use HTML::TreeBuilder;
use HTML::TreeBuilder::XPath;
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


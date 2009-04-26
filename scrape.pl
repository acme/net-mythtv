#!/home/acme/perl-5.10.0/bin/perl
use strict;
use warnings;
use LWP::Simple;
use HTML::TreeBuilder;
use HTML::TreeBuilder::XPath;
use Perl6::Say;
use Date::Manip;
use DateTime::Format::Strptime;
use URI;

my $host = 'http://owl.local';

# Apr 26, 2009 (10:30 AM)
my $parser = DateTime::Format::Strptime->new(
    pattern   => '%b %d, %Y (%I:%M %p)',
    locale    => 'en_GB',
    time_zone => 'Europe/London',
    on_error  => 'croak',
);

my $html = get("$host/mythweb/tv/recorded");

my $ntree = HTML::TreeBuilder::XPath->new;
$ntree->parse_content($html);

my ($table) = $ntree->findnodes('id("recorded_list")');
foreach my $child ( $table->content_list ) {
    my $class = $child->attr('class');
    my $id    = $child->attr('id');
    next unless $id;
    my ($type) = $id =~ /^(.+)_/;
    my @tds = $child->content_list;
    if ( $type eq 'breakrow' ) {
    } elsif ( $type eq 'inforow' ) {
        my $pixmap = $tds[1];
        my $url = URI->new( [ $pixmap->content_list ]->[4]->attr('href') );
        my ( undef, undef, undef, undef, $channel_id, $start_time )
            = split '/', $url->path;

        my $title    = $tds[2]->as_text;
        my $airdate  = $tds[5]->as_text;
        my $dt       = $parser->parse_datetime($airdate);
        my $filename = $title . ' ' . $dt . '.mpg';
        $filename =~ s{[^a-zA-Z0-9.]}{_}g;
        $filename = '/home/acme/Public/tv/' . $filename;

        next if -f $filename;

        say "$url -> $filename";
        mirror( $url, $filename );
        my $delete_url
            = "$host/mythweb/tv/recorded?delete=yes&chanid=$channel_id&starttime=$start_time";
        say $delete_url;
        get($delete_url);

    } elsif ( $type eq 'statusrow' ) {
    }
}

#warn $table->dump;
#warn $table->as_text;

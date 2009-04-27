#!/home/acme/perl-5.10.0/bin/perl
use strict;
use warnings;
use DateTime;
use HTML::TreeBuilder;
use HTML::TreeBuilder::XPath;
use LWP::UserAgent;
use Perl6::Say;
use URI;

my $host = 'http://owl.local';

my $ua = LWP::UserAgent->new;
$ua->default_header( 'Accept-Language' => 'en' );

my $response = $ua->get("$host/mythweb/tv/recorded");
die $response->status_line unless $response->is_success;

my $ntree = HTML::TreeBuilder::XPath->new;
$ntree->parse_content( $response->content );

my ($table) = $ntree->findnodes('id("recorded_list")');
foreach my $child ( $table->content_list ) {
    my $class = $child->attr('class');
    my $id    = $child->attr('id');
    next unless $id;
    my ($type) = $id =~ /^(.+)_/;
    my @tds = $child->content_list;
    next unless $type eq 'inforow';
    my $pixmap = $tds[1];
    my $url = URI->new( [ $pixmap->content_list ]->[4]->attr('href') );
    my ( undef, undef, undef, undef, $channel_id, $start_time ) = split '/',
        $url->path;

    my $title   = $tds[2]->as_text;
    my $actions = $tds[9]->as_text;
    next if $actions =~ /Still Recording/;

    my $dt = DateTime->from_epoch( epoch => $start_time );
    my $filename = $title . ' ' . $dt . '.mpg';
    $filename =~ s{[^a-zA-Z0-9.]}{_}g;
    $filename = '/home/acme/Public/tv/' . $filename;

    next if -f $filename;

    say "$url -> $filename";
    my $mirror_response = $ua->get( $url, ':content_file' => $filename );
    die $mirror_response->status_line unless $mirror_response->is_success;

    my $delete_url
        = "$host/mythweb/tv/recorded?delete=yes&chanid=$channel_id&starttime=$start_time";
    say $delete_url;
    my $delete_response = $ua->get($delete_url);
    die $delete_response->status_line unless $delete_response->is_success;
}


#!/home/acme/perl-5.10.0/bin/perl
use strict;
use warnings;
use DateTime;
use HTML::TreeBuilder;
use HTML::TreeBuilder::XPath;
use LWP::UserAgent;
use Perl6::Say;
use URI;
use URI::QueryParam;

my $host = 'http://owl.local';

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
    my @tds   = $child->content_list;
    my $title = $tds[2]->as_text;
    my ($actions) = $tds[6]->content_list;
    my $url = URI->new( $host . $actions->attr('href') );
    die "Missing dontrec field" unless $url->query_param('dontrec') eq 'yes';
    my ( undef, undef, undef, undef, $channel_id, $start_time ) = split '/',
        $url->path;
    my $dt = DateTime->from_epoch( epoch => $start_time)->set_time_zone('UTC')->set_time_zone('Europe/London');
    say "$title / $channel_id / $start_time / $dt";
}


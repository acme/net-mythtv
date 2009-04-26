#!/home/acme/bin/perl
use strict;
use warnings;
use lib 'lib';
use Net::MythTV;
use Perl6::Say;

my $mythtv = Net::MythTV->new( hostname => 'owl.local' );
my @recordings = $mythtv->recordings;
foreach my $recording (@recordings) {
    my $filename = $recording->title . ' ' . $recording->start . '.mpg';
    $filename =~ s{[^a-zA-Z0-9]}{_}g;
    say $recording->channel . ', '
        . $recording->title . ' '
        . $recording->url . ' '
        . $recording->start . ' - '
        . $recording->stop . ' ('
        . $recording->size . ') -> '
        . $filename;
}

$mythtv->download_recording( $recordings[0], 'test.mpg' );

#$mythtv->send_data("MYTH_PROTO_VERSION 40");
#my $what = $mythtv->read_data;
#say $what;

#!perl
use strict;
use warnings;
use lib 'lib';
use Net::MythTV;
use Perl6::Say;

my $mythtv = Net::MythTV->new( hostname => 'localhost' );
my @recordings = $mythtv->recordings;
foreach my $recording (@recordings) {
    my $filename = $recording->title . ' ' . $recording->start . '.mpg';
    $filename =~ s{[^a-zA-Z0-9]}{_}g;
    say $recording->channel . ', '
        . $recording->title . ' '
        . $recording->start . ' - '
        . $recording->stop . ' ('
        . $recording->size . ') -> '
        . $filename;
    $mythtv->download_recording( $recording, $filename );
}

# BBC TWO, Springwatch 2009-06-11T19:00:00 - 2009-06-11T20:00:00 (3184986020) -> Springwatch_2009_06_11T19_00_00_mpg
# Channel 4, Derren Brown 2009-06-11T22:40:00 - 2009-06-11T23:10:00 (1734615088) -> Derren_Brown_2009_06_11T22_40_00_mpg

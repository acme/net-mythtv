package Net::MythTV;
use Moose;
use MooseX::StrictConstructor;
use DateTime;
use IO::File;
use IO::Socket::INET;
use Net::MythTV::Connection;
use Net::MythTV::Recording;
use Sys::Hostname qw();
use URI;

our $VERSION = '0.33';

has 'hostname' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'localhost',
);

has 'port' => (
    is      => 'rw',
    isa     => 'Int',
    default => 6543,
);

has 'connection' => (
    is       => 'rw',
    isa      => 'Net::MythTV::Connection',
);

__PACKAGE__->meta->make_immutable;

sub BUILD {
    my $self = shift;

    my $connection = Net::MythTV::Connection->new(
        hostname => $self->hostname,
        port     => $self->port,
    );
    my ($ann_status)
        = $connection->send_command(
        'ANN Playback ' . Sys::Hostname::hostname . ' 0' );
    confess("Unable to announce") unless $ann_status eq 'OK';
    $self->connection($connection);
}

sub recordings {
    my $self = shift;
    my @bits = $self->connection->send_command('QUERY_RECORDINGS Play');
    my $nrecordings = shift @bits;
    my @recordings;
    foreach my $i ( 1 .. $nrecordings ) {
        my @parts = splice( @bits, 0, 46 );

        #use YAML; die Dump \@parts;
        my $title   = $parts[0];
        my $channel = $parts[6];
        my $url     = $parts[8];
        my $size    = $parts[10];
        my $start   = DateTime->from_epoch( epoch => $parts[11] );
        my $stop    = DateTime->from_epoch( epoch => $parts[12] );

        # warn "$channel, $title $url $start - $stop ($size)\n";
        push @recordings,
            Net::MythTV::Recording->new(
            title   => $title,
            channel => $channel,
            url     => $url,
            size    => $size,
            start   => $start,
            stop    => $stop,
            );

        #use YAML; die Dump \@parts;
    }

    #die $nrecordings;
    return @recordings;
}

sub download_recording {
    my ( $self, $recording, $destination ) = @_;
    my $command_connection = $self->connection;

    my $uri      = URI->new( $recording->url );
    my $filename = $uri->path;

    my $fh = IO::File->new("> $destination") || die $!;

    my $data_connection = Net::MythTV::Connection->new(
        hostname => $self->hostname,
        port     => $self->port,
    );

    my ( $ann_status, $socket_id, $zero, $total )
        = $data_connection->send_command(
        'ANN FileTransfer ' . Sys::Hostname::hostname . '[]:[]' . $filename );
    confess("Unable to announce") unless $ann_status eq 'OK';
    warn "$ann_status / $socket_id / $zero / $total";

    my ( $seek_status1, $seek_status2 )
        = $command_connection->send_command( 'QUERY_FILETRANSFER '
            . $socket_id . '[]:[]' . 'SEEK' . '[]:[]' . '0' . '[]:[]'
            . '0' );
    confess("Unable to announce")
        unless $seek_status1 == 0 && $seek_status2 == 0;

    while ($total) {
        my ($request_length)
            = $command_connection->send_command( 'QUERY_FILETRANSFER '
                . $socket_id . '[]:[]'
                . 'REQUEST_BLOCK' . '[]:[]'
                . 65535 );
        last unless $request_length;
        while ($request_length) {
            my $bytes
                = $data_connection->socket->read( my $buffer,
                $request_length )
                || die $!;
            $fh->print($buffer) || die $!;
            $request_length -= $bytes;
        }
        $total -= $request_length;
    }
}

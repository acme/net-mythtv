package Net::MythTV::Connection;
use Moose;
use MooseX::StrictConstructor;
my $DEBUG = 0;

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

has 'socket' => (
    is       => 'rw',
    isa      => 'IO::Socket::INET',
    required => 0,
);

__PACKAGE__->meta->make_immutable;

our $BACKEND_SEP = '[]:[]';

sub BUILD {
    my $self = shift;

    my $socket = IO::Socket::INET->new(
        PeerAddr => $self->hostname,
        PeerPort => $self->port,
        Proto    => 'tcp',
        Reuse    => 1,
        Timeout  => 10,
    ) || die $self->hostname . $self->port . ': ' . $!;
    $self->socket($socket);

    my ( $proto_status, $proto_version )
        = $self->send_command("MYTH_PROTO_VERSION 40");
    confess("Wrong protocol version") unless $proto_status eq 'ACCEPT';
}

sub DEMOLISH {
    my $self = shift;
    $self->send_data('DONE');
}

sub send_command {
    my ( $self, $command ) = @_;
    $self->send_data($command);
    my $response = $self->read_data;
    warn "receiving [$response]\n" if $DEBUG;
    return split '\[\]\:\[\]', $response;
}

sub send_data {
    my ( $self, $command ) = @_;

   # The command format should be <length + whitespace to 8 total bytes><data>
    my $data
        = length($command)
        . ' ' x ( 8 - length( length($command) ) )
        . $command;
    warn "sending [$data]\n" if $DEBUG;
    $self->socket->print($data);
}

sub read_data {
    my $self   = shift;
    my $socket = $self->socket;

    my $length;

    # Read the response header to find out how much data we'll be grabbing
    my $result = $socket->read( $length, 8 );
    if ( !defined $result ) {
        warn "Error reading from MythTV backend: $!\n";
        return '';
    } elsif ( $result == 0 ) {

        #warn "No data returned by MythTV backend.\n";
        return '';
    }
    $length = int($length);

    # Read and return any data that was returned
    my $ret;
    my $data;
    while ( $length > 0 ) {
        my $bytes
            = $socket->read( $data, ( $length < 262144 ? $length : 262144 ) );

        # Error?
        last unless ( defined $bytes );

        # EOF?
        last if ( $bytes < 1 );

        # On to the next
        $ret .= $data;
        $length -= $bytes;
    }
    return $ret;
}

package Net::MythTV::Recording;
use Moose;
use MooseX::StrictConstructor;

has 'title' => (
    is  => 'rw',
    isa => 'Str',
);

has 'channel' => (
    is  => 'rw',
    isa => 'Str',
);

has 'url' => (
    is  => 'rw',
    isa => 'Str',
);

has 'size' => (
    is  => 'rw',
    isa => 'Int',
);

has 'start' => (
    is  => 'rw',
    isa => 'DateTime',
);

has 'stop' => (
    is  => 'rw',
    isa => 'DateTime',
);

__PACKAGE__->meta->make_immutable;

1;

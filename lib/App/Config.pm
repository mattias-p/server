package App::Config;
use strict;
use warnings;

use Carp qw( confess );

sub new {
    my ( $class, %args ) = @_;

    my $p_fail = delete $args{p_fail};

    !%args or confess 'unexpected arguments';

    my $self = bless {}, $class;

    $self->{p_fail} = $p_fail;

    return $self;
}

sub load {
    my $self = shift;

    if ($self->{p_fail} > 0 && rand() < $self->{p_fail} ) {
        warn "injected failure";
        return;
    }

    $self->{data} = {
        timeout     => 10,
        max_workers => 2,
    };

    return 1;
}

sub is_loaded {
    my $self = shift;

    return exists $self->{data};
}

sub timeout {
    my $self = shift;

    return $self->{data}{timeout};
}

sub max_workers {
    my $self = shift;

    return $self->{data}{max_workers};
}

1;

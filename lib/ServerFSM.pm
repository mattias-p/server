package ServerFSM;
use strict;
use warnings;
use feature 'say';

use Exporter qw( import );
use FSM::Builder;
use Readonly;
use POSIX qw( pause );

our @EXPORT_OK = qw( new_server_fsm cmp_inputs %INPUT_PRIORITIES $S_LOAD $S_RUN $S_REAP $S_WATCH $S_SLEEP $S_REAP_GRACE $S_WATCH_GRACE $S_SLEEP_GRACE $S_SHUTDOWN $S_EXIT $I_ZERO $I_DONE $I_CHLD $I_USR1 $I_ALRM $I_HUP $I_TERM $I_EXIT );

Readonly our $S_LOAD        => 'LOAD';
Readonly our $S_RUN         => 'RUN';
Readonly our $S_SLEEP       => 'SLEEP';
Readonly our $S_REAP        => 'REAP';
Readonly our $S_WATCH       => 'WATCH';
Readonly our $S_SLEEP_GRACE => 'SLEEP_GRACE';
Readonly our $S_REAP_GRACE  => 'REAP_GRACE';
Readonly our $S_WATCH_GRACE => 'WATCH_GRACE';
Readonly our $S_SHUTDOWN    => 'SHUTDOWN';
Readonly our $S_EXIT        => 'EXIT';

Readonly our $I_ZERO => 'zero';
Readonly our $I_DONE => 'done';
Readonly our $I_CHLD => 'chld';
Readonly our $I_USR1 => 'usr1';
Readonly our $I_ALRM => 'alrm';
Readonly our $I_HUP  => 'hup';
Readonly our $I_TERM => 'term';
Readonly our $I_EXIT => 'exit';

Readonly our %INPUT_PRIORITIES => (
    $I_DONE => 0,
    $I_EXIT => 1,
    $I_TERM => 2,
    $I_CHLD => 3,
    $I_HUP  => 4,
    $I_ALRM => 5,
    $I_USR1 => 6,
    $I_ZERO => 7,
);

Readonly my $BUILDER => FSM::Builder->new();

$BUILDER->define_input(
    $I_ZERO => (
        $S_LOAD        => $S_RUN,
        $S_RUN         => $S_RUN,
        $S_WATCH       => $S_SLEEP,
        $S_SLEEP       => $S_SLEEP,
        $S_REAP        => $S_SLEEP,
        $S_WATCH_GRACE => $S_SLEEP_GRACE,
        $S_SLEEP_GRACE => $S_SLEEP_GRACE,
        $S_REAP_GRACE  => $S_SLEEP_GRACE,
        $S_SHUTDOWN    => $S_SHUTDOWN,
        $S_EXIT        => $S_EXIT,
    )
);

$BUILDER->define_input(
    $I_DONE => (
        $S_LOAD        => $S_RUN,
        $S_RUN         => $S_SLEEP,
        $S_WATCH       => $S_SLEEP,
        $S_SLEEP       => $S_SLEEP,
        $S_REAP        => $S_SLEEP,
        $S_WATCH_GRACE => $S_SLEEP_GRACE,
        $S_SLEEP_GRACE => $S_EXIT,
        $S_REAP_GRACE  => $S_EXIT,
        $S_SHUTDOWN    => $S_EXIT,
        $S_EXIT        => $S_EXIT,
    )
);

$BUILDER->define_input(
    $I_CHLD => (
        $S_LOAD        => $S_REAP,
        $S_RUN         => $S_REAP,
        $S_WATCH       => $S_REAP,
        $S_SLEEP       => $S_REAP,
        $S_REAP        => $S_REAP,
        $S_WATCH_GRACE => $S_REAP_GRACE,
        $S_SLEEP_GRACE => $S_REAP_GRACE,
        $S_REAP_GRACE  => $S_REAP_GRACE,
        $S_SHUTDOWN    => $S_SHUTDOWN,
        $S_EXIT        => $S_EXIT,
    )
);

$BUILDER->define_input(
    $I_ALRM => (
        $S_LOAD        => $S_WATCH,
        $S_RUN         => $S_WATCH,
        $S_WATCH       => $S_WATCH,
        $S_SLEEP       => $S_WATCH,
        $S_REAP        => $S_WATCH,
        $S_WATCH_GRACE => $S_WATCH_GRACE,
        $S_SLEEP_GRACE => $S_WATCH_GRACE,
        $S_REAP_GRACE  => $S_WATCH_GRACE,
        $S_SHUTDOWN    => $S_SHUTDOWN,
        $S_EXIT        => $S_EXIT,
    )
);

$BUILDER->define_input(
    $I_USR1 => (
        $S_LOAD        => $S_RUN,
        $S_RUN         => $S_RUN,
        $S_WATCH       => $S_RUN,
        $S_SLEEP       => $S_RUN,
        $S_REAP        => $S_RUN,
        $S_WATCH_GRACE => $S_SLEEP_GRACE,
        $S_SLEEP_GRACE => $S_SLEEP_GRACE,
        $S_REAP_GRACE  => $S_SLEEP_GRACE,
        $S_SHUTDOWN    => $S_SHUTDOWN,
        $S_EXIT        => $S_EXIT,
    )
);

$BUILDER->define_input(
    $I_HUP => (
        $S_LOAD        => $S_LOAD,
        $S_RUN         => $S_LOAD,
        $S_WATCH       => $S_LOAD,
        $S_SLEEP       => $S_LOAD,
        $S_REAP        => $S_LOAD,
        $S_WATCH_GRACE => $S_SLEEP_GRACE,
        $S_SLEEP_GRACE => $S_SLEEP_GRACE,
        $S_REAP_GRACE  => $S_SLEEP_GRACE,
        $S_SHUTDOWN    => $S_SHUTDOWN,
        $S_EXIT        => $S_EXIT,
    )
);

$BUILDER->define_input(
    $I_TERM => (
        $S_LOAD        => $S_SLEEP_GRACE,
        $S_RUN         => $S_SLEEP_GRACE,
        $S_WATCH       => $S_SLEEP_GRACE,
        $S_SLEEP       => $S_SLEEP_GRACE,
        $S_REAP        => $S_SLEEP_GRACE,
        $S_WATCH_GRACE => $S_SHUTDOWN,
        $S_SLEEP_GRACE => $S_SHUTDOWN,
        $S_REAP_GRACE  => $S_SHUTDOWN,
        $S_SHUTDOWN    => $S_EXIT,
        $S_EXIT        => $S_EXIT,
    )
);

$BUILDER->define_input(
    $I_EXIT => (
        $S_LOAD        => $S_SHUTDOWN,
        $S_RUN,        => $S_SHUTDOWN,
        $S_WATCH       => $S_SHUTDOWN,
        $S_SLEEP,      => $S_SHUTDOWN,
        $S_REAP,       => $S_SHUTDOWN,
        $S_WATCH_GRACE => $S_SHUTDOWN,
        $S_SLEEP_GRACE => $S_SHUTDOWN,
        $S_REAP_GRACE  => $S_SHUTDOWN,
        $S_SHUTDOWN    => $S_EXIT,
        $S_EXIT        => $S_EXIT,
    )
);

sub new_server_fsm {
    return $BUILDER->build( initial_state => $S_LOAD );
}

sub cmp_inputs {
    my ( $a, $b ) = @_;
    $INPUT_PRIORITIES{ $a } <=> $INPUT_PRIORITIES{ $b }
}

sub new {
    my ($class, %params) = @_;
    my $config = delete $params{config};

    my $self = bless {}, $class;

    $self->{fsm} = new_server_fsm();
    $self->{config} = $config;

    return $self;
}

sub do_load {
    my $self = shift;

    if ( $self->{config}->load() ) {
        say "Successfully loaded config";
        return $I_DONE;
    }
    else {
        say "Failed to load config";
        return ( $self->{config}->is_loaded() ) ? () : $I_EXIT;
    }
}

my %actions = (
    $S_LOAD => \&do_load,
    $S_RUN => sub {
        say "Running";
        return rand() < 0.25 ? $I_DONE : ();
    },
    $S_REAP => sub {
        say "Reaping";
        return $I_DONE;
    },
    $S_WATCH => sub {
        say "Watching";
        return $I_DONE;
    },
    $S_SLEEP => sub {
        say "Sleeping";
        pause;
        return;
    },
    $S_REAP_GRACE => sub {
        say "Reaping during graceful shutdown";
        return rand() < 0.25 ? $I_DONE : ();
    },
    $S_WATCH_GRACE => sub {
        say "Watching during graceful shutdown";
        return $I_DONE;
    },
    $S_SLEEP_GRACE => sub {
        say "Sleeping during graceful shutdown";
        pause;
        return;
    },
    $S_SHUTDOWN => sub {
        say "Shutting down forcefully";
        return $I_DONE;
    },
);

sub act {
    my $self  = shift;
    my $state = shift;

    return $actions{$state}->( $self );
}

1;

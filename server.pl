#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';

use AlarmQueue;
use Allocator;
use Config;
use Dispatcher;
use Heap::Binary;
use Idler;
use Readonly;
use Server qw( cmp_inputs $I_IDLE $I_REAP $I_TIMEOUT $I_WORK $I_LOAD $I_TERM );
use Signal qw( install_handler retrieve_caught uninstall_handlers );

sub work {
    my $jid = shift;
    uninstall_handlers();    # reset signal handlers for child process
    sleep( 5 + rand 11 );    # pretend doing something
    return;
}

my $config = Config->new( p_fail => 0.2 );

my $allocator = Allocator->new( p_fail => 0.2 );

my $dispatcher = Dispatcher->new(
    action => \&work,
    p_fail => 0.2,
);

my $alarms = AlarmQueue->new();

my $idler = Idler->new();

my $server = Server->new(
    config     => $config,
    allocator  => $allocator,
    dispatcher => $dispatcher,
    alarms     => $alarms,
    idler      => $idler,
);

my $events = Heap::Binary->new( \&cmp_inputs );
$events->insert($I_LOAD);

say "$$";
install_handler( 'ALRM' );
install_handler( 'CHLD' );
install_handler( 'HUP' );
install_handler( 'TERM' );
install_handler( 'USR1' );

while ( !$server->is_final ) {
    my @events = $server->process( $events->extract_min() // $I_IDLE );

    $events->insert($_) for @events;
    $events->insert($I_TIMEOUT) if retrieve_caught('ALRM');
    $events->insert($I_REAP)    if retrieve_caught('CHLD');
    $events->insert($I_LOAD)    if retrieve_caught('HUP');
    $events->insert($I_TERM)    if retrieve_caught('TERM');
    $events->insert($I_WORK)    if retrieve_caught('USR1');
}

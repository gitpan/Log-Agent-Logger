#
# $Id: Logger.pm,v 0.1 2000/11/06 20:14:13 ram Exp $
#
#  Copyright (c) 2000, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: Logger.pm,v $
# Revision 0.1  2000/11/06 20:14:13  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

use strict;

########################################################################
package Log::Agent::Logger;

use vars qw($VERSION);

$VERSION = '0.100';

use Log::Agent;
use Log::Agent::Formatting qw(format_args);
use Log::Agent::Priorities qw(:LEVELS level_from_prio prio_from_level);

BEGIN {
	no strict 'refs';
	my %fn;
	%fn = (
		'emerg'		=> q/['emerg',   EMERG]/,
		'emergency'	=> q/['emerg',   EMERG]/,
		'alert'		=> q/['alert',   ALERT]/,
		'crit'		=> q/['crit',    CRIT]/,
		'critical'	=> q/['crit',    CRIT]/,
		'err'		=> q/['err',     ERROR]/,
		'error'		=> q/['err',     ERROR]/,
		'warning',	=> q/['warning', WARN]/,
		'warn',		=> q/['warning', WARN]/,
		'notice'	=> q/['notice',  NOTICE]/,
		'info'		=> q/['info',    INFO]/,
		'debug'		=> q/['debug',   DEBUG]/,
	) unless defined &emergency;
	for my $sub (keys %fn) {
		my $prilvl = $fn{$sub};
		*$sub = eval qq{
			sub {
				my \$self = shift;
				if (ref \$_[0] eq 'CODE') {
					\$self->_log_fn($prilvl, \\\@_);
				} else {
					\$self->_log($prilvl, \\\@_);
				}
				return;
			}
		};
	}
}

#
# ->make
#
# Creation routine.
#
# Attributes (and switches that set them):
#
#   -channel	logging channel
#   -max_prio	maximum priority logged (included)
#   -min_prio	minimum priority logged (included)
#
sub make {
	my $self = bless {}, shift;
	my (%args) = @_;
	my $prefix;

	my %set = (
		-channel	=> \$self->{channel},
		-max_prio	=> \$self->{max_prio},
		-min_prio	=> \$self->{min_prio},
	);

	while (my ($arg, $val) = each %args) {
		my $vset = $set{lc($arg)};
		unless (ref $vset) {
			require Carp;
			Carp::croak("Unknown switch $arg");
		}
		$$vset = $val;
	}

	#
	# Always use numeric priorities internally
	#

	$self->{max_prio} = DEBUG unless defined $self->{max_prio};
	$self->{min_prio} = EMERG unless defined $self->{min_prio};

	$self->{max_prio} = level_from_prio($self->{max_prio})
		if $self->{max_prio} =~ /^\D+$/;

	$self->{min_prio} = level_from_prio($self->{max_prio})
		if $self->{min_prio} =~ /^\D+$/;

	return $self;
}

#
# Attribute access
#

sub channel			{ $_[0]->{channel} }
sub max_prio		{ $_[0]->{max_prio} }
sub min_prio		{ $_[0]->{min_prio} }

sub max_prio_str	{ prio_from_level $_[0]->{max_prio} }
sub min_prio_str	{ prio_from_level $_[0]->{min_prio} }

sub set_max_prio
	{ $_[0]->{max_prio} = $_[1] =~ /^\D+$/ ? level_from_prio($_[1]) : $_[1] }
sub set_min_prio
	{ $_[0]->{min_prio} = $_[1] =~ /^\D+$/ ? level_from_prio($_[1]) : $_[1] }

#
# ->close
#
# Close underlying channel, and detach from it.
#
sub close {
	my $self = shift;
	my $channel = $self->{channel};
	return unless defined $channel;		# Already closed
	$self->{channel} = undef;
	$channel->close;
}

#
# ->_log
#
# Emit log at given priority, if within priority bounds.
#
sub _log {
	my ($self, $prilvl) = splice(@_, 0, 2);
	my $channel = $self->{channel};
	return unless defined $channel;			# Closed

	#
	# Prune call if we're not within bounds.
	# $prilvl is seomthing like ["error", ERROR].
	#

	my $lvl = $prilvl->[1];
	return if $lvl > $self->{max_prio} || $lvl < $self->{min_prio};

	#
	# Issue logging.
	#

	$channel->write($prilvl->[0], &format_args);
	return;
}

#
# ->_log_fn
#
# Emit log at given priority, if within priority bounds.
# The logged string needs to be computed by calling back a routine.
#
sub _log_fn {
	my ($self, $prilvl) = splice(@_, 0, 2);
	my $channel = $self->{channel};
	return unless defined $channel;			# Closed

	#
	# Prune call if we're not within bounds.
	# $prilvl is seomthing like ["error", ERROR].
	#

	my $lvl = $prilvl->[1];
	return if $lvl > $self->{max_prio} || $lvl < $self->{min_prio};

	#
	# Issue logging.
	#

	my $fn = shift @{$_[0]};
	my $msg = &$fn(@{$_[0]});
	return unless length $msg;				# Null messsage, don't log

	$channel->write($prilvl->[0], $msg);
	return;
}

1;	# for require
__END__

=head1 NAME

Log::Agent::Logger - a logging interface

=head1 SYNOPSIS

 require Log::Agent::Logger;
 
 my $log = Log::Agent::Logger->make(
     -channel    => $chan,
     -max_prio   => 'info',
     -min_prio   => 'emerg',
 );
 $log->error("can't open file %s: $!", $file);
 $log->warning("can't open file: $!");

=head1 DESCRIPTION

The C<Log::Agent::Logger> class defines a generic interface for application
logging.  It must not be confused with the interface provided by Log::Agent,
which is meant to be used by re-usable modules that do not wish to commit
on a particular logging method, so that they remain true building blocks.

By contrast, C<Log::Agent::Logger> explicitely requests an object to be used,
and that object must commit upon the logging channel to be used, at creation
time.

Optionally, minimum and maximum priority levels may be defined (and changed
dynamically) to limit the messages to effectively log, depending on the
advertised priority.  The standard syslog(3) priorities are used.

=head1 CHANNEL LIST

The following channels are available:

=head2 Standard Log::Agent Channels

Those channels are documented in L<Log::Agent::Channel>.

=head2 Other Channels

Future C<Log::Agent::Logger> extension will extend the set of available
channels.

=head1 INTERFACE

=head2 Creation Routine

The creation routine is called C<make> and takes the following switches:

=over

=item C<-channel>

This defines the C<Log::Agent::Channel> to be used for logging.
Leaving this undefined will create a logger object that will never
output anything.

=item C<-min_prio>

Defines the minimum priority to be logged (included).  Defaults to "emerg".

=item C<-max_prio>

Defines the maximum priority to be logged (included).  Defaults to "debug".

=back

=head2 Logging Interface

Each routine is documented to take a single string, but you may
also supply a code reference as the first argument, followed by extra
arguments.  That routine will be called, along with the extra arguments,
to generate the message to be logged.  If that sounds crazy, think about
the CPU time we save by NOT calling the routine.  If nothing is returned
by the routine, nothing is logged.

If more than one argument is given, and the first argument is not a
code reference, then it is taken as a printf() format, and the remaining
arguments are used to fill the various "%" placeholders in the format.
The special "%m" placeholder does not make use of any extra argument and
is replaced by a stringification of the error message contained in $!,
aka C<errno>.

There is a logging routine defined for each syslog(3) priority, along
with aliases for some of them.  Here is an exhaustive table, sorted by
decreasing priority.

    Syslog     Alias
    --------   ---------
    emerg      emergency
    alert
    crit       critical
    err        error
    warning    warn
    notice
    info
    debug

We shall document only one routine for a given level: for instance,
we document C<warn> but you could also use the standard C<warning> to
achieve exactly the same funciton.

=over

=item C<emergency($str)>

Log at the "emerg" level, usually just before panicing.  Something
terribly bad has been detected, and the program might crash soon after
logging this.

=item C<alert($str)>

Log at the "alert" level, to signal a problem requiring immediate
attention.  Usually, some functionality will be missing until the
condition is fixed.

=item C<critical($str)>

Log at the "crit" level, to signal a severe error that prevents fulfilling
some activity.

=item C<error($str)>

Log at the "err" level, to signal a regular error.

=item C<warn($str)>

Log at the "warning" level, which is an indication that something unusual
occurred.

=item C<notice($str)>

Log at the "notice" level, indicating something that is fully handled
by the applicaiton, but which is not the norm.  A significant condition,
as they say.

=item C<info($str)>

Log at the "info" level, for their amusement.

=item C<debug($str)>

Log at the "debug" level, to further confuse them.

=back

=head2 Closing Channel

=over

=item C<close>

This routine closes the channel.  Furhter logging to the logger is
permitted, but will be simply discarded without notice.

=back

=head2 Attribute Access

The following access routines are defined:

=over

=item C<channel>

The defined logging channel.  Cannot be changed.

=item C<max_prio> and C<max_prio_str>

Returns the maximum priority recorded, either as a numeric value
or as a string.  For the correspondance between the two, see
L<Log::Agent::Priorities>.

=item C<min_prio> and C<min_prio_str>

Returns the minimum priority recorded, either as a numeric value
or as a string.  For the correspondance between the two, see
L<Log::Agent::Priorities>.

=item C<set_max_prio($prio)> and C<set_min_prio($prio)>

Used to modify the maximum/minimum priorities.  You can use either
the string value or the numerical equivalent, as documented
in L<Log::Agent::Priorities>.

=back

=head1 AUTHOR

Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>

=head1 SEE ALSO

Log::Agent::Channel(3).

=cut

#!./perl

#
# $Id: caller.t,v 0.1.1.1 2001/04/11 16:15:54 ram Exp $
#
#  Copyright (c) 2000, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: caller.t,v $
# Revision 0.1.1.1  2001/04/11 16:15:54  ram
# patch1: created
#
# Revision 0.2.1.1  2001/03/13 18:45:44  ram
# patch2: test the ${line} variable substitution
#
# Revision 0.2  2000/11/06 19:30:33  ram
# Baseline for second Alpha release.
#
# $EndLog$
#

print "1..5\n";

require 't/code.pl';
sub ok;

my $logfile = "logfile-caller.t";

sub cleanlog() {
	unlink <$logfile>;
}

require Log::Agent::Channel::File;
require Log::Agent::Logger;

cleanlog;

my $channel = Log::Agent::Channel::File->make(
	-prefix     => "foo",
	-stampfmt   => "own",
	-showpid    => 1,
    -filename   => $logfile,
    -share      => 1,
);

my $log = Log::Agent::Logger->make(
	-channel  => $channel,
	-max_prio => 'info',
	-caller   => [ -format => "<%s,%.4d>", -info => "sub line", -postfix => 1 ],
);

my $show_error = __LINE__ + 2;
sub show_error {
	$_[0]->error("error string");
}

sub notice_string { "notice string" }

my $show_notice = __LINE__ + 2;
sub show_notice {
	$_[0]->notice(\&notice_string);
}

show_error($log);
show_notice($log);

$log->set_caller_info(-display => "<nothing>");
$log->error("error2 string");

$log->set_caller_info();
$log->error("error3 string");

$log->close;

my $error_str = sprintf("%.4d", $show_error);
my $notice_str = sprintf("%.4d", $show_notice);

ok 1, contains($logfile, "error string <main::show_error,$error_str>");
ok 2, contains($logfile, "notice string <main::show_notice,$notice_str>");
ok 3, contains($logfile, '<nothing> error2 string');
ok 4, contains($logfile, 'error3 string');
ok 5, !contains($logfile, '> error3 string$');

#cleanlog;


#!./perl

#
# $Id: priority.t,v 0.1.1.1 2001/04/11 16:15:58 ram Exp $
#
#  Copyright (c) 2000, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: priority.t,v $
# Revision 0.1.1.1  2001/04/11 16:15:58  ram
# patch1: created
#
# Revision 0.2.1.1  2001/03/13 18:48:06  ram
# patch2: fixed bug for *BSD systems
# patch2: created
#
# Revision 0.2  2000/11/06 19:30:33  ram
# Baseline for second Alpha release.
#
# $EndLog$
#

print "1..6\n";

require 't/code.pl';
sub ok;

sub cleanlog() {
	unlink <t/logfile*>;
}

require Log::Agent::Channel::File;
require Log::Agent::Logger;

cleanlog;
my $file = "t/logfile";
my $channel = Log::Agent::Channel::File->make(
	-prefix     => "foo",
	-stampfmt   => "own",
	-showpid    => 1,
    -filename   => $file,
    -share      => 1,
);

my $log = Log::Agent::Logger->make(
	-channel  => $channel,
	-max_prio => 'info',
	-priority => [ -display => '<$priority/$level>', -prefix => 1 ],
);

$log->error("error string");
$log->notice("notice string");
$log->info("info string");

$log->set_priority_info(-display => '<$priority>');
$log->info("info2 string");

$log->set_priority_info();
$log->info("info3 string");

$log->close;

ok 1, contains($file, "<error/3> error string");
ok 2, contains($file, "<notice/6> notice string");
ok 3, contains($file, "<info/8> info string");
ok 4, contains($file, "<info> info2 string");
ok 5, contains($file, "info3 string");
ok 6, !contains($file, "> info3 string");

cleanlog;


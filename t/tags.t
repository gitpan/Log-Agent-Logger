#!./perl

#
# $Id: tags.t,v 0.1.1.1 2001/04/11 16:16:02 ram Exp $
#
#  Copyright (c) 2000, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: tags.t,v $
# Revision 0.1.1.1  2001/04/11 16:16:02  ram
# patch1: created
#
# Revision 0.2.1.1  2001/03/13 18:49:29  ram
# patch2: created
#
# Revision 0.2  2000/11/06 19:30:33  ram
# Baseline for second Alpha release.
#
# $EndLog$
#

print "1..2\n";

require 't/code.pl';
sub ok;


$logfile = 'logfile-tags.t';

sub cleanlog() {
	unlink <$logfile>;
}

require Log::Agent::Channel::File;
require Log::Agent::Logger;
require Log::Agent::Tag::String;

cleanlog;

my $channel = Log::Agent::Channel::File->make(
	-prefix     => "foo",
	-stampfmt   => "own",
	-showpid    => 1,
    -filename   => $logfile,
    -share      => 1,
);

my $t1 = Log::Agent::Tag::String->make(-value => "<tag #1>");
my $t2 = Log::Agent::Tag::String->make(-value => "<tag #2>", -postfix => 1);

my $log = Log::Agent::Logger->make(
	-channel  => $channel,
	-max_prio => 'info',
	-tags     => [$t1],
);

$log->err("error string");
$log->tags->append($t2);
$log->warn("warn string");

ok 1, contains($logfile, '<tag #1> error string');
ok 2, contains($logfile, '<tag #1> warn string <tag #2>');

#cleanlog;


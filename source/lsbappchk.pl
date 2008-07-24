#!/usr/bin/perl
# prototype application to check perl applications
# for LSB compliance
# uses perldeps.pl from the rpm-build package
# Copyright GPL, Stew Benedict <stewb@linuxfoundation.org>

# tet stuff blows up with strict
#use strict;
our $VERSION = "lsbappchk.pl 0.2 (noarch)";
our $basedir = "/opt/lsb";
our $max_version = 5.008999;
our $perl_version = "5.8.X with X >= 8 (<= " . $max_version . ")";
package tet;

use Getopt::Long;
use File::Basename;

our $JOURNAL_HANDLE;
my $journal = '';
my $lsb_version = "4.0";
# @ARGV get's clobbered somewhere
my $fullargs = join(' ', @ARGV);
my $options = GetOptions("journal" => \$journal, "version=s" => \$lsb_version);

our @TET_CODE_FILE=("0   PASS        Continue\n",
	"1   FAIL        Continue\n",
	"2   UNRESOLVED  Continue\n",
	"3   NOTINUSE    Continue\n",
	"4   UNSUPPORTED Continue\n",
	"5   UNTESTED    Continue\n",
	"6   UNINITIATED Continue\n",
	"7   NORESULT    Continue\n");

require "/opt/lsb/share/appchk/perldeps.pl";
require "/opt/lsb-tet3-lite/lib/perl/api.pl";

sub time {
    my ($sec,$min,$hour)=localtime;
    my $r=sprintf("%02d:%02d:%02d",$hour,$min,$sec);
}

sub test_time {
    my ($sec,$min,$hour,$mday,$mon,$year)=localtime;
    $year += 1900;
    my $r=sprintf("%02d:%02d:%02d %04d%02d%02d",$hour,$min,$sec,$year,$mon+1,$mday)
}

sub test_start {
    my ($tnum)  = @_;
    my $time=&time;
    &output(400, "$tnum $tnum $time", "IC Start");
    &setcontext;
}

sub tp_start {
    my ($tnum, $message) = @_;
    my $time=&time;
    &output(200, "$tnum $time", "TP Start, $message");
}

sub test_end {
    my ($tnum)  = @_;
    my $time=&time;
    &output(410, "$tnum $tnum $time", "IC End");
}

sub test_result {
    my ($tnum, $result) = @_;
    $resnum = 0;
    my $time=&time;
    if ("$result" eq "") {
        $result="NORESULT";
        $resnum = 7;
    } elsif (&getcode($result)!=0) {     # sets $resnum & $abort
        $result="NO RESULT NAME";
        $resnum=-1;
    }
    &output(220, "$tnum $resnum $time", "$result");
}

sub test_info {
    my ($tnum, $message) = @_;
    my $time=&time;
    &output(520, "$tnum $time", "$message");
}

sub test_header {
    my $login=getpwuid($<);
    my $id_string = "0|3.7-lite " . &tet::test_time . "|User: " . $login . " , Command line: " . $0 . " " . $fullargs . "\n"; 
    printf($JOURNAL_HANDLE $id_string);
    my $uname = `uname -snrvm`;
    chomp $uname;
    my $host_info = "5|" . $uname . "|System Information\n";
    printf($JOURNAL_HANDLE $host_info);
    my $vfile = "/opt/lsb/share/appchk/VERSION.lsbappchk.pl";
    open(VFILE, $vfile) || die "Could not open $vfile\n";
    while (defined($line = <VFILE>)) {
        $test_ver = $line;
    }
    $test_ver = "30||VSX_NAME=" . $VERSION;
    printf($JOURNAL_HANDLE "$test_ver\n");
    printf($JOURNAL_HANDLE "40||Config End\n");
}

sub test_footer {
    my $time=&time;
    &output(80, "0 $time", "TC End") if $journal;
    $activity=$time;
    &output(900, "", "TCC End") if $journal;
}

sub file_info {
    my ($file) = @_;

    my $size = -s "$file";

    use Digest::MD5;
    open(FILE, $file) or die "Could not open $file\n";
    binmode(FILE);
    my $md5sum = Digest::MD5->new->addfile(*FILE)->hexdigest;
    close FILE;

    &output(520, "1 1 0 0", "FILE_SIZE $size");
    &output(520, "1 0 0 0", "BINARY_MD5SUM $md5sum");
}

# read the list of LSB modules
my $mlistf = "$basedir/share/appchk/lsb-perl-modules.list";
open(MFILE, $mlistf) || die "Could not open $mlistf\n";

my $line;
my @mlist;
while (defined($line = <MFILE>)) {
    chomp $line;
    push @mlist, $line;
}
close MFILE;

my $argc = @ARGV;
die "Usage $0 [-j|--journal] [-v|--version=N.N (LSB version to test for, default is $lsb_version)] [filename(s)]\n" if $argc == 0;

# semi-reasonable max for a while
if ($lsb_version < 1.0 or $lsb_version > 20) {
    die "Invalid LSB version: $lsb_version";
}

my $deps = new DependencyParser;
for my $file (grep /^[^-]/, @ARGV) {
    $deps->process_file($file);
    print "$file tested against LSB $lsb_version:\n";

    if ($journal) {
        my $journal_path="journal." . basename($0) . "." . basename($file);
        unlink($journal_path);
        if (open(JHNDL,">>$journal_path")) {
            $JOURNAL_HANDLE = JHNDL;
        }
        #no matter what, make sure output is unbuffered.
        select((select($JOURNAL_HANDLE), $|=1)[0]);

        test_header();
        my $time=&time;
        tet::output(10, "$file $time", "TC Start") if $journal;
        &output(15, "tetj-1.0 1", "TCM Start") if $journal;
    }

    my $tnum = 1;
    # collect file size and md5sum as test 1
    test_start($tnum) if $journal;
    tp_start($tnum, "File information") if $journal;
    file_info($file) if $journal;
    test_result($tnum, "PASS") if $journal;
    test_end($tnum) if $journal;
    my $verbage = "is used, but is not part of LSB";
    my $vermsg = "but LSB specifies " . $perl_version;
    my $appearedmsg = "did not appear until LSB ";
    my $withdrawnmsg = "was withdrawn in LSB ";
    for my $req ($deps->requires) {
        $tnum++;
        my $value = $req->value;
        test_start($tnum) if $journal;
        tp_start($tnum, "Check $value") if $journal;
        my @match = grep { /^$value/ } @mlist;
        my ($module, $appeared, $withdrawn) = split(' ', $match[0]);
        my $found = @match;
        if ($found) {
            if ($lsb_version < $appeared) {
                $appearedmsg = $module . ' ' . $appearedmsg;
                printf("  %s%s\n", $appearedmsg, $appeared);  
                if ($journal) {
                    test_info($tnum, $appearedmsg . $appeared);
                    test_result($tnum, "FAIL");
                }
            } elsif ($lsb_version > $withdrawn and $withdrawn ne 'NULL') {
                $withdrawnmsg = $module . ' ' . $withdrawnmsg;
                printf("  %s%s\n", $withdrawnmsg, $withdrawn);  
                if ($journal) {
                    test_info($tnum, $withdrawnmsg . $withdrawn);
                    test_result($tnum, "FAIL");
                }
            } else {
                if ($journal) {
                    test_result($tnum, "PASS");
                }
            }
        } else {
            if ($req->type eq 'perl version') {
                # required perl version cannot be more than 5.8.X
                # test fails for plain 5.X.X, with no leading "v"
                # and silently passes things like v5.9.X
                # try to reformat and check that value too
                $value =~ s/^v//;
                my ($major, $minor, $release) = split(/\./, $value);
                my $newvalue = sprintf("%d.%03d%03d", $major, $minor, $release);
                if ($value > $max_version && $newvalue > $max_version) {
                    printf "  Requires perl version %s %s\n", $req->value, $vermsg;
                    if ($journal) {
                        test_info($tnum, "Requires perl version " . $req->value . " " . $vermsg);
                        test_result($tnum, "FAIL");
                    }
                } else {
                    test_result($tnum, "PASS") if $journal;
                }	
            } else {
                printf "  %s %s\n", $req->value, $verbage;
                if ($journal) {
                    test_info($tnum, $req->value . " " . $verbage);
                    test_result($tnum, "FAIL");
                }
            }
        }
        test_end($tnum) if $journal;
    }
    test_footer();
    close JHNDL if $journal;
}



#!/usr/bin/perl
# prototype application to check perl applications
# for LSB compliance
# uses perldeps.pl from the rpm-build package
# Copyright GPL, Stew Benedict <stewb@linux-foundation.org>

# tet stuff blows up with strict
#use strict;
our $VERSION = "lsbappchk.pl 0.1 (noarch)";
our $basedir = "/opt/lsb";
package tet;

use Getopt::Long;
use File::Basename;

our $JOURNAL_HANDLE;
my $journal = '';
my $options = GetOptions("journal" => \$journal);

our @TET_CODE_FILE=("0   PASS        Continue\n",
	"1   FAIL        Continue\n",
	"2   UNRESOLVED  Continue\n",
	"3   NOTINUSE    Continue\n",
	"4   UNSUPPORTED Continue\n",
	"5   UNTESTED    Continue\n",
	"6   UNINITIATED Continue\n",
	"7   NORESULT    Continue\n");

require "/opt/lsb/lib/appchk/perldeps.pl";
require "/opt/lsb-tet3-lite/lib/perl/api.pl";

sub time {
  my ($sec,$min,$hour)=localtime;
  my $r=sprintf("%02d:%02d:%02d",$hour,$min,$sec);
}

sub test_time {
  my ($sec,$min,$hour,$mday,$mon,$year)=localtime;
  my $year += 1900;
  my $r=sprintf("%02d:%02d:%02d %04d%02d%02d",$hour,$min,$sec,$year,$mon,$mday)
}

sub test_start {
  my ($tnum)  = @_;
  my $time=&time;
  &output(400, "$tnum $tnum $time", "IC Start");
  &setcontext;
}

sub test_end {
  my ($tnum)  = @_;
  my $time=&time;
  &output(410, "$tnum $tnum $time", "IC End");
}

sub test_result {
  my ($tnum, $result) = @_;
  $resnum;
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
  my $id_string = "0|3.7-lite " . &tet::test_time . "|User: " . $login . " , Command line: " . $0 . "\n"; 
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
}

sub file_info {
  my ($file) = @_;

  my $size = -s "$file";

  use Digest::MD5;
  open(FILE, $file) or die "Could not open $file\n";
  binmode(FILE);
  my $md5sum = Digest::MD5->new->addfile(*FILE)->hexdigest;
  close FILE;

  &output(520, "0 1 0 0 0", "FILE_SIZE $size");
  &output(520, "0 1 0 0 0", "BINARY_MD5SUM $md5sum");
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
die "Usage $0 [-j|--journal] [filename(s)]\n" if $argc == 0;

my $deps = new DependencyParser;
for my $file (grep /^[^-]/, @ARGV) {
  $deps->process_file($file);
  print "$file:\n";

  if ($journal) {
    my $journal_path="journal." . basename($0) . "." . basename($file);
    unlink($journal_path);
    if (open(JHNDL,">>$journal_path")) {
      $JOURNAL_HANDLE = JHNDL;
    }
    #no matter what, make sure output is unbuffered.
    select((select($JOURNAL_HANDLE), $|=1)[0]);

    test_header();
    tet::output(10, "$file", "TC Start") if $journal;
  }

  my $tnum = 1;
  # collect file size and md5sum as test 1
  test_start($tum) if $journal;
  file_info($file) if $journal;
  test_result($tnum, "PASS") if $journal;
  test_end($tnum) if $journal;
  for my $req ($deps->requires) {
    $tnum++;
    my $verbage = "is used, but is not part of LSB";
    my $value = $req->value;
    test_start($tnum) if $journal;
    test_info($tnum, "Check $value") if $journal;
    my @match = grep { /^$value/ } @mlist;
    my $found = @match;
    if ($found) {
      if ($journal) {
        test_result($tnum, "PASS");
      }
    } else {
      printf "  %s %s\n", $req->value, $verbage;
      if ($journal) {
	test_info($tnum, $req->value . " " . $verbage);
        test_result($tnum, "FAIL");
      }
    }
    test_end($tnum) if $journal;
  }
  close JHNDL if $journal;
}



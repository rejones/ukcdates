#!/usr/bin/perl

# $Id$

# Generate repeating events in a format suitable for converting to Palm 
# datebook .dba format with convdb
#
# Author: Richard Jones, April 2006

use strict;
use Getopt::Long;
use vars qw($opt_h $opt_v);

#Date:Calc doesn't seem available on MacOS X
use Date::Calc qw(Add_Delta_Days);
use Date::Manip qw(ParseDate UnixDate);

my $DEFAULT_LABEL = 'Kent Week';
my $label = $DEFAULT_LABEL;
my $DEFAULT_PERIOD = 7;
my $period = $DEFAULT_PERIOD;
my $DEFAULT_NUMBER = 1;
my $number = $DEFAULT_NUMBER;

# This note provide a colour for REJ's DateBk5 calendar (currently not used)
#my $NOTE = '##@@@@@@@@@@@@@@@@V=0D=0A';

my $usage = 'events.pl [-h] [-v] [-l label] [-p period] [-s start] day/month/year repeat...';

sub help($);
sub printDBAhdr();
sub printVCALhdr();
sub printDBA($$$$$);
sub printVCAL($$$$$);


GetOptions("h"     => \$opt_h,
           "l=s"   => \$label,
           "p=i"   => \$period,
           "s=i"   => \$number,
            "v"    => \$opt_v);
if($opt_h) {
  help($usage);
  exit 0;
}

die "Bad period $period.\n$usage" unless $period > 0;
#print Dumper(@ARGV);
die "Bad number of arguments $#ARGV.\n$usage" if ($ARGV % 2 != 0);


Date::Manip::Date_Init("Language=English","DateFormat=".$ENV{TZ});
# Print header
if ($opt_v) {
  printVCALhdr();
} else {
  printDBAhdr();
}

while ($#ARGV > 0) {
  my $arg = shift;
  my $date = ParseDate($arg);
  #print Dumper($date);
  die "$arg is a bad date.\n$usage" unless $date;
  my ($year, $month, $day) = UnixDate($date, "%Y", "%m", "%d");
  
  my $repeat = shift;
  die "Bad repeat $repeat.\n$usage" unless $repeat > 0;

  for (my $i = 0; $i < $repeat; $i++) {
    if ($opt_v) {
      printVCAL($day,$month,$year, $label, $number);
    } else {
      printDBA($day,$month,$year, $label, $number);
    }
    ($year, $month, $day) = Add_Delta_Days($year, $month, $day, $period);
    $number++;
  }
}

#print trailer
printEOVCAL() if $opt_v;


# SUBROUTINES -----------------------------------------

# write header
# format is:
# day/month/year	hour:minute	duration	details (HW=highwater)
sub printDBAhdr () {
  print "#Repeated dates generated by event.pl\n";
  printf "%s\t%s\t%s\t%s\t%s\n", '%d/%m/%y', '%h:%i', '%t', '%u', '%v';
  print "\n";
}

# vCal header
sub printVCALhdr() {
  print <<"EOVH"
BEGIN:VCALENDAR
PRODID:Richard Jones events.pl generated
TZ:+00
VERSION:1.0
EOVH
}

# Print .dba entry
sub printDBA($$$$$) {
  my ($day,$month,$year, $label, $number) = @_;
  printf "%s/%s/%s\t09:00\t1\tY\t%s\n", $day,$month,$year, "$label $number";
}

# Print vCal entry
sub printVCAL($$$$$) {
  my ($num,$month,$year, $label, $number) = @_;
  my $T = 'T';
  #my $OOZ = '00Z';
  my $OOZ = '00';
  my $start = '0900';
  my $day = sprintf "%4d%02d%02d", $year, $month, $num;
  print "BEGIN:VEVENT\n";
  print "SUMMARY:$label $number\n";
  print "DTSTART:$day$T$start$OOZ\n";
  print "DTEND:$day$T$start$OOZ\n";
  print "END:VEVENT\n";
}

# vCal trailer
sub printEOVCAL() {
  print "END:VCALENDAR\n";
}


# 
# Print help message
#
sub help($) {
my $usage = shift;
  print <<"EOT"
$usage
events.pl expects groups of 2 arguments. It will generate a list of dates for
each group, starting with the date given and repeated repeat times.
Options:
  -h	    Print this message and exit.
  -l label  Print each event as "label N" where N is the number of the event.
            Default: $DEFAULT_LABEL.
  -p period The repeat period. Default: $DEFAULT_PERIOD;
  -s start  The starting number for the label. Default: $DEFAULT_NUMBER.
  -v	    Use vCal format rather than .dba.
EOT
}

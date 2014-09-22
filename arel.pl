#!/usr/bin/perl

use strict;
use CGI qw(:standard);
use LWP::Simple;
use Date::Calc qw(Add_Delta_Days);

my $qedt = new CGI;

if ($qedt->param()) { #Have we been given a login through GET?

my $login = $qedt->param('login');

#set up ical file
print header(-type=>'text/calendar',
			#-nph=>1,
			-charset=>'utf-8',
			-attachment=>"calendar-".$login.".ics");

print "BEGIN:VCALENDAR
VERSION:2.0
CALSCALE:GREGORIAN
X-WR-CALNAME:EISTI-DEUSEDT
X-WR-TIMEZONE:Europe/Paris
PRODID:-//eeisti/pussykudasai//iCal 3.0//EN"."\n";



my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time); #I don't need all these variables but fuckthat

#$mon++;
my($y1, $m1, $d1) = Add_Delta_Days($year, $mon+1, $mday, -35);
my $localdate = $d1."_".$m1."_".($y1+1900);

my($y2, $m2, $d2) = Add_Delta_Days($year, $mon+1, $mday, 35);
my $futuredate = $d2."_".$m2."_".($y2+1900);

my $url = "http://edt.atilla.org/search?login=".$login."&from=".$localdate."&to=".$futuredate;
#my $url = "http://edt.atilla.org/search?login=".$login."&from=21_6_2014&to=".$futuredate;

my $content = get($url); #Let's query edt.atilla.org.
die "Couldn't get it!" unless defined $content; #fail if login unavailable or some random error in the API

#print $url;

#The $content is formed of a bunch of these:
# {"salle": "TG201", "groupe": "I1C", "professeur": "Caulier Nicole", "debut": "2013-12-02T08:30:00", "libelle": "Algebre", "libelle_court": "EX", "libelle2": "ALGEBRE-", "fin": "2013-12-02T10:30:00"},

#What we want is:
#BEGIN:VEVENT
#DTSTART:20131202T083000Z
#DTEND:20131202T103000Z
#ORGANIZER;CN=Caulier Nicole 
#SUMMARY:EX: Algebre (ALGEBRE-) 
#LOCATION: TG201
#END:VEVENT

#define variables 
my $summary="";
my $organizer="";
my $location="";
my $dstart="",
my $dend="";

#Remove initial "[{" and final "}]" (2 chars)
$content = substr $content, 2, -2;

#print $content;

#We split $content according to the leftover "}, {" marks.
my @classes = split(/},\s{/, $content);
#@classes now contains strings in the form of: 
#"salle": "TG308", "groupe": "I1C", "professeur": "Fintz Nesim", "debut": "2014-07-18T09:00:00", "libelle": "Espace Scolarite", "libelle_court": null, "libelle2": "JURY RECOURS:L3:", "fin": "2014-07-18T12:00:00"

#Each string represents a class session. We'll parse those, and add a VEVENT to $ical for each string.
my $vevent =""; #The VEVENT we'll create at each iteration will be stored here, and appended to $ical.
my @values;

foreach (@classes)
{ #The string is stored in $_.
#Let's remove unneeded parts.
@values = split(/,\s/,$_);

#print $values[0]."\n";
#print $values[1]."\n";
#print $values[2]."\n";
#print $values[3]."\n";
#print $values[4]."\n";
#print $values[5]."\n";
#print $values[6]."\n";
#print $values[7]."\n";
#print $values[8]."\n";

#regexmagic
my $regex = qr/"*.":\s*"([^"]+)"\s*/;

#activate it
if( $values[3] =~ $regex || next)
	{$dstart = $1;}
if( $values[4] =~ $regex || next)
	{$summary = $1;}
if( $values[5] =~ $regex )
	{$summary = qq($summary - $1);}
if( $values[0] =~ $regex || next)
	{
	$location= $1;
	$summary = qq($summary \($1\));
	}
if( $values[2] =~ $regex || next)
	{
	$organizer= $1;
	$summary = qq($summary - $1);;
	}
if( $values[7] =~ $regex || next)
	{$dend = $1;}

#if( $values[1] =~ $regex || next)
#	{$groupe = $1;}
#if( $values[6] =~ $regex || next)
#	{$summary_court = qq($summary \($1\));}
	
$dstart =~ s/://g;
$dstart =~ s/-//g;
$dend =~ s/://g;
$dend =~ s/-//g;

#print $location;

$vevent = "BEGIN:VEVENT
DTSTART:".$dstart."
DTEND:".$dend."
ORGANIZER;CN=".$organizer.":mailto:undefined
SUMMARY:".$summary." 
LOCATION:".$location."
END:VEVENT";

print $vevent."\n";

}

#We're done here.
print "END:VCALENDAR"; 
}
else
{
print header;
print begin_html;
print 'oukilsont les arguments pd';
print end_html;
}


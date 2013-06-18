#!/usr/bin/perl
# Changelog
# =======================================
# v1.0 Krisztian Banhidy initial release
#
#This file is part of Leats.
##
##Leats is free software: you can redistribute it and/or modify
##it under the terms of the GNU General Public License as published by
##the Free Software Foundation, either version 3 of the License, or
##(at your option) any later version.
##
##Leats is distributed in the hope that it will be useful,
##but WITHOUT ANY WARRANTY; without even the implied warranty of
##MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##GNU General Public License for more details.
##
##You should have received a copy of the GNU General Public License
##along with Leats.  If not, see <http://www.gnu.org/licenses/>.
#############
#our $author='Krisztian Banhidy <krisztian@banhidy.hu>';
our $author='Richard Gruber <gruberrichard@gmail.com>';
our $version="v0.9";
our $topic="06-rights";
our $problem="2";
our $description="LEVEL:	Beginner

- Create directory /mnt/dir1/dir2/dir3/dir4/
- Move /mnt/files/2.alert_catp.log to /mnt/dir1/dir2/dir3/dir4/
- Change the owner group to group01
- The members of group01 have to be able to write it
- Change the owner of the file to jesse
- User jesse can only read the files
- Others should not have any rights on the file
";

our $hint="Move the given file (mv). Change the owners and groups (chown, chgrp).
Change permissions (chmod).";
#
#
#
#############
our $verbose=0;
my $help=0;
my $break=0;
my $grade=0;
my $hint=0;
my $desc=0;
use strict;
use warnings;
use Getopt::Long;
use Term::ANSIColor;
use File::Basename;
use Exporter;
use POSIX qw/strftime/;
our $name=basename($0);
use lib '/scripts/common_perl/';
use Framework qw($verbose $topic $author $version $hint $problem $name $exercise_number $exercise_success $student_file $result_file &printS &cryptText2File &decryptFile &EncryptResultFile $description &showdescription);
use UserGroup qw($verbose &userExist &groupExist &getUserAttribute &checkUserAttribute &checkUserPassword &checkUserGroupMembership &checkUserSecondaryGroupMembership &checkUserPrimaryGroup &checkGroupNameAndID &checkUserChageAttribute &checkUserLocked &setupUser &setupGroup &delGroup &delUser &checkUserFilePermission &checkGroupFilePermission &checkOtherFilePermission &checkUserFileSpecialPermission &checkNewlyCreatedFilesAttributes );
use Disk qw(&fileEqual &checkOwner &checkGroup &checkType &checkSymlink &Delete &Move &Copy &CreateDirectory );
use System qw(&CopyFromDesktop);
######
###Options
###
GetOptions("help|?|h" => \$help,
		"verbose|v" => \$verbose,
		"b|break" => \$break,
		"g|grade" => \$grade,
		"hint" => \$hint,
		"d|description" => \$desc,
	  );

#####
# Subs
#
sub break() {
	print "Break has been selected.\n";

	&pre();	#Reset server machine

	CreateDirectory("/mnt/files","","","");
	setupGroup("group01","","");
        setupUser("jesse","","","","","","","");
	System::CopyFromDesktop("/ALTS/ExerciseScripts/logs/TGZ/ALL.tgz","/mnt/files/compressed.tgz","700","","","decompressTGZ");

        system("cp -p /ALTS/EXERCISES/$topic/$problem-grade /var/www/cgi-bin/Grade 1>/dev/null 2>&1; chmod 6555 /var/www/cgi-bin/Grade");
	$verbose and print "Pre complete breaking\n";
	print "Your task: $description\n";
}

sub grade() {

	system("clear");
	my $Student = Framework::getStudent();

	my $T=$topic; $T =~ s/\s//g;
	$result_file="/ALTS/RESULTS/${Student}/${T}-${problem}"; #Empty the result file
		my $fn; open($fn,">","$result_file"); close($fn);
	my $now = strftime "%Y/%m/%d %H:%M:%S", localtime;
	$exercise_number = 0;
	$exercise_success = 0;

	my $L=65;

	print "="x$L."=========\n";
	print "Student:\t$Student\n\n";
	print "Date:   \t$now\n";
	print "-"x$L."---------\n\n";
	print "$topic/$problem\n";
	print "\n$description\n\n";
	print "="x$L."=========\n\n";

	my $USERDATA=decryptFile("$student_file");
	cryptText2File("<ROOT>$USERDATA<DATE>$now</DATE><TOPIC>$topic</TOPIC><PROBLEM>$problem</PROBLEM><DESCRIPTION>$description</DESCRIPTION>","$result_file");


	my $Dir="/mnt/dir1/dir2/dir3/dir4";
	my $File="$Dir/2.alert_catp.log";

	printS("Directory $Dir exist","$L");
	Framework::grade(checkType("$Dir","directory"));

        printS("$File exist","$L");
        Framework::grade(checkType("$File","regular file"));

	printS("/mnt/files/2.alert_catp.log not exist","$L");
        Framework::grade(!checkType("/mnt/files/2.alert_catp.log","regular file"));


	printS("The owner group is group01","$L");
	Framework::grade(checkGroup("$File","group01"));

        printS("Group01 can write it","$L");
        Framework::grade(checkGroupFilePermission("group01","$File","*w*"));
 
        printS("The owner is jesse","$L");
        Framework::grade(checkOwner("$File","jesse"));
 
        printS("Jesse can only read it","$L");
        Framework::grade(checkUserFilePermission("jesse","$File","r--") );
  
        printS("Other can't read, write or execute it","$L");
        Framework::grade(checkOtherFilePermission("$File","---"));




	print "\n"."="x$L."=========\n";
	print "\n\tNumber of exercises: \t$exercise_number\n";
	print "\n\tSuccessful: \t\t$exercise_success\n";
	if ($exercise_number == $exercise_success) {
		cryptText2File("<TASKNUMBER>$exercise_number</TASKNUMBER><TASKSUCCESSFUL>$exercise_success</TASKSUCCESSFUL><FINALRESULT>PASSED</FINALRESULT></ROOT>","$result_file");
		print color 'bold green' and print "\n\n\tSuccessful grade.\n\n"  and print color 'reset';
		&EncryptResultFile();
		#Running post
		&post();
		exit 0;
	}
	else
	{
		cryptText2File("<TASKNUMBER>$exercise_number</TASKNUMBER><TASKSUCCESSFUL>$exercise_success</TASKSUCCESSFUL><FINALRESULT>FAILED</FINALRESULT></ROOT>","$result_file");
		print color 'bold red' and print "\n\n\tUnsuccessful grade. Please try it again!\n\n"  and print color 'reset';
		&EncryptResultFile();
		exit 1;
	}

}

sub pre() {
### Prepare the machine 
	$verbose and print "Running pre section\n";

	$verbose and print "Reseting server...\n";
        system("/ALTS/RESET");


}

sub post() {
### Cleanup after succeful grade
}

#####
# Main
if ( $help ) {
	Framework::useage;
}

if ( $hint ) {
	Framework::hint;
}

if ( $desc ) {
        Framework::showdescription;
}


if ( $grade and $break ) {
	print "Break and grade cannot be requested at one time.\n";
	Framework::useage;
}

if ( $break ) {
	&break;
} elsif ( $grade ) {
	&grade;
} else {
	print "Nothing has been selected. Please select one option.\n";
	Framework::useage;
}

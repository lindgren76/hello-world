#!/usr/bin/perl
use strict;
use POSIX qw(strftime);
use DBI;
use Getopt::Long; qw(GetOpt);

# Andra funktionen pa argumenthanteringen
Getopt::Long::Configure ("bundling");

my $PROGRAM_NAME="newfs";
my $VERSION="0.0.1";
my $RELEASE_DATE="2015-12-07";
my $ProjNr;
my $RunNr;
my $ForceNr;
my $Additional;
my $User = getlogin();

sub get_run_nr($)
{
    $ProjNr = $_[0];
    #Set these:
	my $Server='GHS-DTC01';
	my $Database = 'PE';
    my $DSN = "mssql-dtc";
    my $dbh = DBI->connect("dbi:ODBC:$DSN", 'sa', 'Elvira92800', {PrintError => 0});
    my $sth = $dbh->prepare("SELECT TOP(1) RunNumber FROM FSRun WHERE [Gestamp Project Number]='$ProjNr' ORDER BY RunNumber DESC")
    	or die "Can't prepare statment: $DBI::errstr";
    if($sth->execute) {
	while(my @dat = $sth->fetchrow) {
	    $RunNr=$dat[0];
	    return $RunNr;
	}
    }
    $dbh->disconnect;
    return 0;
}

sub insert_new_run($$$)
{
    $ProjNr = $_[0];
    $RunNr = $_[1];
    #$User = $_[2];
	my $User = $ENV{LOGNAME} || $ENV{USER} || getpwuid($<);
	my $now = strftime "%Y-%m-%d %H:%M:%S", localtime;
	#printf("test %s", $now);
    $RunNr = sprintf("%03d",$RunNr);
    my $DSN = "mssql-dtc";
    my $dbh = DBI->connect("dbi:ODBC:$DSN", 'sa', 'Elvira92800', {PrintError => 0});
    my $sth = $dbh->prepare("INSERT INTO FSRun ([Gestamp Project Number], RunNumber, Sign, Date) VALUES ('$ProjNr','$RunNr','$User', '$now')")
    	or die "Can't prepare statment: $DBI::errstr";
	#my $now = strftime "%Y-%m-%d %H:%M:%S", localtime;
	#$sth->bind_param(1, $now, SQL_DATETIME);
    $sth->execute();
	#if($sth->execute) {
	#while(my @dat = $sth->fetchrow) {
	#    return 0;
	#}
    #}
    $dbh->disconnect;
    return -1;
}


sub create_new_run($$$)
{
	$ProjNr = $_[0];
	$RunNr = $_[1];
	$User = $_[2];
#	if($RunNr==1){
    		#print("Previus run for project $ProjNr is $RunNr \n");
		$RunNr++;
    		insert_new_run($ProjNr, $RunNr, $User);
		#print("Your run number is $RunNr\n");
		create_run_folder($ProjNr, $RunNr);
		return $RunNr;
}

sub create_run_folder($$)
{
    $ProjNr = $_[0];
    $RunNr = $_[1];
    my $folder = "\FS-$ProjNr-run$RunNr";
    rw();
    mkdir $folder or die "\nCannot create /$folder: $!\n";
    mkdir "$folder\/mesh" or die "\nCannot create /$folder/mesh: $!\n";
    ro();
    printf("\FS-$ProjNr-run$RunNr created\n");                      
}


sub get_proj_nr
{

    my $path = `pwd`;
    chomp $path;
    my @parsepath = split('/', $path); 
    my $len = @parsepath;
    $|=1;
    if ($parsepath[$len-1] =~ /^\d\d\d\d$/) {
        print "Enter Project Number: ($parsepath[$len-1]) ";
    }
    else {
        print "Enter Project Number: ";
    }  
    chomp(my $project_number=<STDIN>);
    $project_number = "$parsepath[$len-1]" if $project_number eq '';
    if ($project_number =~ /^\d\d\d\d$/) {
        #print "You have entered $project_number\n";
	$ProjNr = $project_number;
    	return $ProjNr;
    }
    else {
        print "\Project Number must be 4 digits\n";
        get_proj_nr();
    }
}

sub options() {

my $i;
my $proj_number;
my $force_run;

if ($#ARGV < 0) {
    $ProjNr = get_proj_nr();
    $RunNr = get_run_nr($ProjNr);
}

$i = -1;
while ($i < $#ARGV) {
    if ($i+1 <= $#ARGV) {
        if ($ARGV[$i+1] =~ /^-p$/) {
			if ($ARGV[$i+3] =~ //^-f$/) {
				$force_run = $ARGV[$i+2]
				
				}
            $i++;
            $proj_number = $ARGV[$i+1];
	    if ($proj_number =~ /^\d\d\d\d$/) {
        	#print "You have entered $proj_number\n";
			$ProjNr = $proj_number;
			$RunNr = get_run_nr($ProjNr);
			return $ProjNr;
    	    }
    	    else {
                print "\Project Number must be 4 digits\n";
                get_proj_nr();
    	    }
        }
	elsif ($ARGV[$i+1] =~ /^-f$/) {
            $i++;
            $ForceNr = $ARGV[$i+1];
        }
        elsif ($ARGV[$i+1] =~ /^-h$/ || $ARGV[$i+1] =~ /^--help$/) {
            usage();
            exit;
        }
        elsif ($ARGV[$i+1] =~ /^-/) {
            printf("%s: invalid option: %s\n", $PROGRAM_NAME, $ARGV[$i+1]);
            die "Try `$PROGRAM_NAME --help' for more information\n";
        }
        else {
	    #$unprocessed_input = $ARGV[$i+1];
	    #printf("Unprocessed inpuit: $unprocessed_input\n");
        }
    }

    $i++;
  }
if ($ProjNr eq '') {
    $ProjNr = get_proj_nr();
    $RunNr = get_run_nr($ProjNr);
    if ($ForceNr eq '') {
        #do nothing
    }
    else {
        if($ForceNr-1>$RunNr) {
	    $RunNr = $ForceNr-1;
	}
	else {
	    printf("I higher run number ($RunNr) exists in database, this is not allowed!\n");
	    exit;
	}
    }
}
#printf("Parameter -p=$ProjNr runnr =$RunNr\n");
#printf("Parameter -p=$proj_number parameter -f=$force_run\n");

}

# Chmod functions
my $path;
sub rw {
    $path = `pwd`;
    if(-e $path){
        `/usr/local/sbin/ch_perm 775 $path`;
    }
}

sub ro {
    $path = `pwd`;
    if(-e $path) {
        `/usr/local/sbin/ch_perm 755 $path`;
    }
}

sub main()
{

    options();
    create_new_run($ProjNr, $RunNr, $User);

}


main();

sub usage
{
    printf("This program assigns a unique forming run-ID and create a run\nfolder for each separate run\n");
    printf("Version: %s\n", $VERSION);
    printf("Released: %s\n", $RELEASE_DATE);
    printf("\nUsage: %s -p PROJECT_NUMBER -f FIRST_RUN_NUMBER\n", $PROGRAM_NAME);
    printf("\nAvailable options\n");
    printf("=======================================================================================\n");
    printf("-p PROJECT_NUMBER           Project Number\n");
    printf("-f FIRST_RUN_NUMER          Force to start from a predefined run number\n");
    printf("                            (only availible one time in each project)\n");
    printf("-h, --help                  Show this message and exit\n");
    exit(1);
}

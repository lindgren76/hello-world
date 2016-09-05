#!/usr/bin/perl
use strict;
use POSIX qw(strftime);
use DBI;
use Getopt::Long;
#use warnings;

my $PROGRAM_NAME="listfs";
my $VERSION="0.0.1";
my $RELEASE_DATE="2015-12-07";
my ( $Col0, $Col1, $Col2, $Col3, $Col4, $Col5, $Col6, $Col7 );
my ( $runid, $sign, $projnr, $name, $exact, $help );
my $User = getlogin();
    

sub help()
{
    printf("This program displays simulations from the database.\n");
    printf("Version: %s\n", $VERSION);
    printf("Released: %s\n", $RELEASE_DATE);
    printf("\nUsage: %s [OPTION]\n", $PROGRAM_NAME);
    printf("\nAvailable options\n");
    printf("===============================================================\n");
    printf("-r, -runid     Search by runID\n");
    printf("-p, -projnr    Search by Project number\n");
    printf("-s, -sign      Search by user name\n");
    printf("-n, -name      Search by simulation name (broad match)\n");
	printf("-e, -exact     Search by simulation name (exact match)\n");
    printf("-h, -help      Show this message and exit\n");
}
	
sub options () {

	# Process options.
	if ( @ARGV > 0 ) {
	    GetOptions(
			'r|runid:i'   => \$runid,
			'p|projnr:i'  => \$projnr,
			's|sign:s'    => \$sign,
			'n|name:s'  => \$name,
			'e|exact:s'  => \$exact,
			'h|help|?!'     => \$help,
		) or die "Incorrect usage!\n";
	}
	if ( $help ) {
	    help();
		exit;
	} else {
		#print "My name is $name.\n";
	}
}

sub listAll()
{
	my $myQuery;
	my $aQuery = "SELECT [runID], [Gestamp Project Number], [RunNumber], [Name], [Path], [Sign], [Date], ISNULL([Comment], '') AS Comment FROM FSRun";
	my ( $whereQuery, $b1Query, $b2Query, $b3Query, $b4Query, $b5Query ) = "";
	my $cQuery = "ORDER BY runID DESC";
	
	if ($runid) {
		$b1Query = "[runID]='$runid'";	
	}
	if ($sign) {
		$b2Query = "[Sign]='$sign'"
	}
	if ($projnr) {
		$b3Query = "[Gestamp Project Number]='$projnr'"
	}
	if ($name) {
		$b4Query = "[Name] LIKE '%$name%'"
	}
	if ($exact) {
		$b5Query = "[Name] = '$exact'"
	}
	if (($runid) || ($sign) || ($projnr) || ($name) || ($exact)) {
		$whereQuery = "WHERE";
	}
	my $bQuery =  $b1Query . " " . $b2Query . " " . $b3Query . " " . $b4Query . " " . $b5Query;
	
	my $myQuery = $aQuery . " " . $whereQuery . " " . $bQuery . " " . $cQuery;
	
	
    my $DSN = "mssql-dtc";
    my $dbh = DBI->connect("dbi:ODBC:$DSN", 'sa', 'Elvira92800', {PrintError => 0});
    my $sth = $dbh->prepare($myQuery)
    	or die "Can't prepare statment: $DBI::errstr";
    if($sth->execute) {
		printf("%-8s", "RunID");
		printf("%-8s", "ProjNr");
		printf("%-8s", "Run");
		printf("%-26s", "Name");
		printf("%-26s", "Path");
		printf("%-12s", "Sign");
		printf("%-26s", "Date");
		printf("%-10s", "Comment");
		print "\n";
	while(my @row = $sth->fetchrow) {
	    $Col0 = $row[0];
		$Col1 = $row[1];
		$Col2 = $row[2];
		$Col3 = $row[3];
		$Col4 = $row[4];
		$Col5 = $row[5];
		$Col6 = $row[6];
		$Col7 = $row[7];
		printf("%-8s", "$Col0");
		printf("%-8s", "$Col1");
		printf("%-8s", "$Col2");
		printf("%-26s", "$Col3");
		printf("%-26s", "$Col4");
		printf("%-12s", "$Col5");
		printf("%-10s", "$Col6");
		printf("%-10s", "$Col7");
		print "\n";
	}
    }
    $dbh->disconnect;
    return 0;
}

sub main()
{
	options();
	listAll();
}


main();



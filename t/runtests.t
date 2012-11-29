use strict;
use warnings;

use Data::Dumper;
use Test::More;
use Getopt::Long;

use Server;

my $debug=0;
my $localServer=0;
my $getoptResult=GetOptions(
	'debug' =>      \$debug,
	'localServer'   =>      \$localServer,
);

my ($url,$pid);
# would be good to extract the port from a config file or env variable
$url='http://localhost:7060' unless ($localServer);
# Start a server on localhost if desired
($pid, $url) = Server::start($ARGV[0]) unless ($url);
print "Testing service $ARGV[0] on $url\n";

print "-> attempting to connect to:'".$url."'\n";
my $client;
use_ok("Bio::KBase::$ARGV[0]::Client","use Client");

my $eval = "use Bio::KBase::$ARGV[0]::Client; \$client = Bio::KBase::$ARGV[0]::Client->new(\$url);";
eval $eval;

my $objectNames = 'Genome IsComposedOf Contig';
my $filterClause = 'Genome(id) IN (?, ?) ORDER BY Genome(id)';
my $parameters = ['kb|g.0', 'kb|g.1'];
my $fields = 'Genome(id) Genome(dna_size) Contig(id) Contig(source-id)';
my $count = 3;
my $res = $client->GetAll($objectNames, $filterClause, $parameters, $fields, $count);
my $expected = [
          [
            'kb|g.0',
            '4639221',
            'kb|g.0.c.1',
            '83333.1:NC_000913'
          ],
          [
            'kb|g.1',
            '90927236',
            'kb|g.1.c.0',
            '104341.3:scaffold_5006'
          ],
          [
            'kb|g.1',
            '90927236',
            'kb|g.1.c.1',
            '104341.3:scaffold_4628'
          ]
        ];
    
is_deeply($res, $expected, 'checking simple query');
Server::stop($pid, $url) if ($pid);

done_testing(1);

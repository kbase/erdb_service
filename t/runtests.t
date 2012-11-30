use strict;
use warnings;

use Data::Dumper;
use Test::More;
use Getopt::Long;

use Server;

my $debug=0;
my $localServer=0;
my $host='localhost';
my $port;
my $serviceName;

my $getoptResult=GetOptions(
	'debug' =>      \$debug,
	'localServer'   =>      \$localServer,
	'host=s'	=>	\$host,
	'port=i'	=>	\$port,
	'serviceName=s'	=>	\$serviceName,
);

my $num_tests = 0;

my ($url,$pid);
# would be good to extract the port from a config file or env variable
$url="http://$host:$port/" unless ($localServer);
# Start a server on localhost if desired
($pid, $url) = Server::start($serviceName) unless ($url);
print "Testing service $serviceName on $url\n";

my $class="Bio::KBase::$serviceName::Client";
use_ok($class,"use Client");

++$num_tests;

print "-> attempting to connect to:'".$url."'\n";
my $client=new_ok($class=>[ $url ]);

++$num_tests;

isa_ok($client,$class, "Is it the right class?");

++$num_tests;

my $objectNames = 'Genome IsComposedOf Contig';
my $filterClause = 'Genome(id) IN (?, ?) ORDER BY Genome(id)';
my $parameters = ['kb|g.0', 'kb|g.1'];
my $fields = 'Genome(id) Genome(dna_size) Contig(id) Contig(source-id)';
my $count = 3;
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
    
{
	my $res = $client->GetAll($objectNames, $filterClause, $parameters, $fields, $count);
	is_deeply($res, $expected, 'checking simple query, objectNames space-separated string');

	++$num_tests;
}

{
	my $objectNames='Genome IsComposedOf Contig IsLocusFor Feature Produces ProteinSequence AND Feature IsAnnotatedBy Annotation';
	my $filterClause='Genome(id) = ? AND Feature(feature-type) = "CDS"';
	my $parameters=['kb|g.0'];
	my $fields='Genome(scientific-name) Feature(function) Feature(id) Annotation(comment) IsComposedOf(from-link) IsLocusFor(from-link) ProteinSequence(sequence) ProteinSequence(id)';
	my $count=3;
	
	my $expected= [
          [
            'Escherichia coli K12',
            'Thr operon leader peptide',
            'kb|g.0.peg.634',
            'Set function to
Thr operon leader peptide',
            'kb|g.0',
            'kb|g.0.c.1',
            'MKRISTTITTTITITTGNGAG',
            '13fe4258b37e32edda386faa50ec5fdf'
          ],
          [
            'Escherichia coli K12',
            '',
            'kb|g.0.peg.2173',
            'Set function to
Aspartokinase I (EC 2.7.2.4) / Homoserine dehydrogenase I (EC 1.1.1.3)',
            'kb|g.0',
            'kb|g.0.c.1',
            'MRVLKFGGTSVANAERFLRVADILESNARQGQVATVLSAPAKITNHLVAMIEKTISGQDALPNISDAERIFAELLTGLAAAQPGFPLAQLKTFVDQEFAQIKHVLHGISLLGQCPDSINAALICRGEKMSIAIMAGVLEARGHNVTVIDPVEKLLAVGHYLESTVDIAESTRRIAASRIPADHMVLMAGFTAGNEKGELVVLGRNGSDYSAAVLAACLRADCCEIWTDVDGVYTCDPRQVPDARLLKSMSYQEAMELSYFGAKVLHPRTITPIAQFQIPCLIKNTGNPQAPGTLIGASRDEDELPVKGISNLNNMAMFSVSGPGMKGMVGMAARVFAAMSRARISVVLITQSSSEYSISFCVPQSDCVRAERAMQEEFYLELKEGLLEPLAVTERLAIISVVGDGMRTLRGISAKFFAALARANINIVAIAQGSSERSISVVVNNDDATTGVRVTHQMLFNTDQVIEVFVIGVGGVGGALLEQLKRQQSWLKNKHIDLRVCGVANSKALLTNVHGLNLENWQEELAQAKEPFNLGRLIRLVKEYHLLNPVIVDCTSSQAVADQYADFLREGFHVVTPNKKANTSSMDYYHQLRYAAEKSRRKFLYDTNVGAGLPVIENLQNLLNAGDELMKFSGILSGSLSYIFGKLDEGMSFSEATTLAREMGYTEPDPRDDLSGMDVARKLLILARETGRELELADIEIEPVLPAEFNAEGDVAAFMANLSQLDDLFAARVAKARDEGKVLRYVGNIDEDGVCRVKIAEVDGNDPLFKVKNGENALAFYSHYYQPLPLVLRGYGAGNDVTAAGVFADLLRTLSWKLGV',
            '0f66dc2b3024a9739d0e912fde12b8ba'
          ],
          [
            'Escherichia coli K12',
            '',
            'kb|g.0.peg.2173',
            'Set function to
Aspartokinase (EC 2.7.2.4) / Homoserine dehydrogenase (EC 1.1.1.3)',
            'kb|g.0',
            'kb|g.0.c.1',
            'MRVLKFGGTSVANAERFLRVADILESNARQGQVATVLSAPAKITNHLVAMIEKTISGQDALPNISDAERIFAELLTGLAAAQPGFPLAQLKTFVDQEFAQIKHVLHGISLLGQCPDSINAALICRGEKMSIAIMAGVLEARGHNVTVIDPVEKLLAVGHYLESTVDIAESTRRIAASRIPADHMVLMAGFTAGNEKGELVVLGRNGSDYSAAVLAACLRADCCEIWTDVDGVYTCDPRQVPDARLLKSMSYQEAMELSYFGAKVLHPRTITPIAQFQIPCLIKNTGNPQAPGTLIGASRDEDELPVKGISNLNNMAMFSVSGPGMKGMVGMAARVFAAMSRARISVVLITQSSSEYSISFCVPQSDCVRAERAMQEEFYLELKEGLLEPLAVTERLAIISVVGDGMRTLRGISAKFFAALARANINIVAIAQGSSERSISVVVNNDDATTGVRVTHQMLFNTDQVIEVFVIGVGGVGGALLEQLKRQQSWLKNKHIDLRVCGVANSKALLTNVHGLNLENWQEELAQAKEPFNLGRLIRLVKEYHLLNPVIVDCTSSQAVADQYADFLREGFHVVTPNKKANTSSMDYYHQLRYAAEKSRRKFLYDTNVGAGLPVIENLQNLLNAGDELMKFSGILSGSLSYIFGKLDEGMSFSEATTLAREMGYTEPDPRDDLSGMDVARKLLILARETGRELELADIEIEPVLPAEFNAEGDVAAFMANLSQLDDLFAARVAKARDEGKVLRYVGNIDEDGVCRVKIAEVDGNDPLFKVKNGENALAFYSHYYQPLPLVLRGYGAGNDVTAAGVFADLLRTLSWKLGV',
            '0f66dc2b3024a9739d0e912fde12b8ba'
          ]
        ];
	my $res;
	ok($res = $client->GetAll($objectNames, $filterClause, $parameters, $fields, $count),'more complicated query succeeds');
	++$num_tests;
	is_deeply($res, $expected, 'more complicated query matches expected output');

	++$num_tests;
}
{
#	my $objectNames='Genome IsComposedOf Contig IsLocusFor Feature Produces ProteinSequence AND Feature IsAnnotatedBy Annotation';
	my $objectNames='Annotation Annotates Feature AND ProteinSequence IsProteinFor Feature IsLocatedIn Contig IsComponentOf Genome';
	my $filterClause='Genome(id) = ? AND Feature(feature-type) = "CDS"';
	my $parameters=['kb|g.0'];
	my $fields='Genome(scientific-name) Feature(function) Feature(id) Annotation(comment) IsComponentOf(to-link) IsLocatedIn(to-link) ProteinSequence(sequence) ProteinSequence(id)';
	my $count=3;
	
	my $expected= [
          [
            'Escherichia coli K12',
            'Thr operon leader peptide',
            'kb|g.0.peg.634',
            'Set function to
Thr operon leader peptide',
            'kb|g.0',
            'kb|g.0.c.1',
            'MKRISTTITTTITITTGNGAG',
            '13fe4258b37e32edda386faa50ec5fdf'
          ],
          [
            'Escherichia coli K12',
            '',
            'kb|g.0.peg.2173',
            'Set function to
Aspartokinase I (EC 2.7.2.4) / Homoserine dehydrogenase I (EC 1.1.1.3)',
            'kb|g.0',
            'kb|g.0.c.1',
            'MRVLKFGGTSVANAERFLRVADILESNARQGQVATVLSAPAKITNHLVAMIEKTISGQDALPNISDAERIFAELLTGLAAAQPGFPLAQLKTFVDQEFAQIKHVLHGISLLGQCPDSINAALICRGEKMSIAIMAGVLEARGHNVTVIDPVEKLLAVGHYLESTVDIAESTRRIAASRIPADHMVLMAGFTAGNEKGELVVLGRNGSDYSAAVLAACLRADCCEIWTDVDGVYTCDPRQVPDARLLKSMSYQEAMELSYFGAKVLHPRTITPIAQFQIPCLIKNTGNPQAPGTLIGASRDEDELPVKGISNLNNMAMFSVSGPGMKGMVGMAARVFAAMSRARISVVLITQSSSEYSISFCVPQSDCVRAERAMQEEFYLELKEGLLEPLAVTERLAIISVVGDGMRTLRGISAKFFAALARANINIVAIAQGSSERSISVVVNNDDATTGVRVTHQMLFNTDQVIEVFVIGVGGVGGALLEQLKRQQSWLKNKHIDLRVCGVANSKALLTNVHGLNLENWQEELAQAKEPFNLGRLIRLVKEYHLLNPVIVDCTSSQAVADQYADFLREGFHVVTPNKKANTSSMDYYHQLRYAAEKSRRKFLYDTNVGAGLPVIENLQNLLNAGDELMKFSGILSGSLSYIFGKLDEGMSFSEATTLAREMGYTEPDPRDDLSGMDVARKLLILARETGRELELADIEIEPVLPAEFNAEGDVAAFMANLSQLDDLFAARVAKARDEGKVLRYVGNIDEDGVCRVKIAEVDGNDPLFKVKNGENALAFYSHYYQPLPLVLRGYGAGNDVTAAGVFADLLRTLSWKLGV',
            '0f66dc2b3024a9739d0e912fde12b8ba'
          ],
          [
            'Escherichia coli K12',
            '',
            'kb|g.0.peg.2173',
            'Set function to
Aspartokinase (EC 2.7.2.4) / Homoserine dehydrogenase (EC 1.1.1.3)',
            'kb|g.0',
            'kb|g.0.c.1',
            'MRVLKFGGTSVANAERFLRVADILESNARQGQVATVLSAPAKITNHLVAMIEKTISGQDALPNISDAERIFAELLTGLAAAQPGFPLAQLKTFVDQEFAQIKHVLHGISLLGQCPDSINAALICRGEKMSIAIMAGVLEARGHNVTVIDPVEKLLAVGHYLESTVDIAESTRRIAASRIPADHMVLMAGFTAGNEKGELVVLGRNGSDYSAAVLAACLRADCCEIWTDVDGVYTCDPRQVPDARLLKSMSYQEAMELSYFGAKVLHPRTITPIAQFQIPCLIKNTGNPQAPGTLIGASRDEDELPVKGISNLNNMAMFSVSGPGMKGMVGMAARVFAAMSRARISVVLITQSSSEYSISFCVPQSDCVRAERAMQEEFYLELKEGLLEPLAVTERLAIISVVGDGMRTLRGISAKFFAALARANINIVAIAQGSSERSISVVVNNDDATTGVRVTHQMLFNTDQVIEVFVIGVGGVGGALLEQLKRQQSWLKNKHIDLRVCGVANSKALLTNVHGLNLENWQEELAQAKEPFNLGRLIRLVKEYHLLNPVIVDCTSSQAVADQYADFLREGFHVVTPNKKANTSSMDYYHQLRYAAEKSRRKFLYDTNVGAGLPVIENLQNLLNAGDELMKFSGILSGSLSYIFGKLDEGMSFSEATTLAREMGYTEPDPRDDLSGMDVARKLLILARETGRELELADIEIEPVLPAEFNAEGDVAAFMANLSQLDDLFAARVAKARDEGKVLRYVGNIDEDGVCRVKIAEVDGNDPLFKVKNGENALAFYSHYYQPLPLVLRGYGAGNDVTAAGVFADLLRTLSWKLGV',
            '0f66dc2b3024a9739d0e912fde12b8ba'
          ]
        ];
	my $res;
	ok($res = $client->GetAll($objectNames, $filterClause, $parameters, $fields, $count),'more complicated reverse query succeeds');
	++$num_tests;
	is_deeply($res, $expected, 'more complicated reverse query matches expected output');

	++$num_tests;
}

{
	my $objectNames='Genome IsComposedOf Feature';
	my $testName='objectNames bad relationship';
	eval{$client->GetAll($objectNames, $filterClause, $parameters, $fields, $count);};
	like($@, qr/There is no path/,$testName);

	++$num_tests;
}

{
	my $objectNames=['Genome','IsComposedOf','Contig'];
	my $testName='objectNames bad type';
	eval{$client->GetAll($objectNames, $filterClause, $parameters, $fields, $count);};
	like($@, qr/Invalid type/,$testName);

	++$num_tests;
}

{
	my $testName='fields bad type';
	my $fields = [];
	eval{$client->GetAll($objectNames, $filterClause, $parameters, $fields, $count);};
	like($@, qr/Invalid type/,$testName);

	++$num_tests;
}

{
	my $testName='fields bad field name';
	my $fields = 'blah';
	eval{$client->GetAll($objectNames, $filterClause, $parameters, $fields, $count);};
	like($@, qr/Field .* not found in/,$testName);

	++$num_tests;
}

{
	my $testName='parameter bad type';
	my $parameters = 'hello';
	eval{$client->GetAll($objectNames, $filterClause, $parameters, $fields, $count);};
	like($@, qr/Invalid type/,$testName);

	++$num_tests;
}

{
	my $testName='filter bad type';
	my $filterClause = [];
	eval{$client->GetAll($objectNames, $filterClause, $parameters, $fields, $count);};
	like($@, qr/Invalid type/,$testName);

	++$num_tests;
}

Server::stop($pid, $url) if ($pid);

done_testing($num_tests);

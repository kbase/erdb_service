use Bio::KBase::CDMI::CDMI;
use Data::Dumper;

$cdmi = Bio::KBase::CDMI::CDMI->new(DBD => '/kb/deployment/lib/KSaplingDBD_Published.xml',
									 dbhost => '127.0.0.1',
									 port => 49998);

$objectNames = 'Genome IsComposedOf Contig';
$filterClause = 'Genome(id) IN (?, ?) ORDER BY Genome(id)';
$parameters = ['kb|g.0', 'kb|g.1'];
$fields = 'Genome(id) Genome(dna_size) Contig(id) Contig(source-id)';
$count = 10;


my @return = $cdmi->GetAll($objectNames, $filterClause, $parameters, $fields, 3);
print Dumper(@return);

my $return = [$cdmi->GetAll($objectNames, $filterClause, $parameters, $fields, 3)];
print Dumper($return);

1;



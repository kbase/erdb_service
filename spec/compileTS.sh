perl /kb/dev_container/modules/typecomp/scripts/compile_typespec.pl \
	-impl Bio::KBase::ERDB_Service::ERDB_ServiceImpl \
	-psgi ERDB_Service.psgi \
	-service Bio::KBase::ERDB_Service::Server \
	-client Bio::KBase::ERDB_Service::Client \
	-js javascript/ERDB_ServiceClient \
	-py biokbase/erdb_service/client \
	erdb_service.spec \
	../lib

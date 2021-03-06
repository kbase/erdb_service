# configurable variables 
SERVICE = erdb_service
SERVICE_NAME = ERDB_Service
SERVICE_NAME_PY = erdb_service
SERVICE_PSGI_FILE = $(SERVICE_NAME).psgi
SERVICE_CONFIG_NAME = erdb
SERVICE_PORT = 7099

#standalone variables which are replaced when run via /kb/dev_container/Makefile
TOP_DIR = ../..
DEPLOY_RUNTIME ?= /kb/runtime
TARGET ?= /kb/deployment

#for the reboot_service script, we need to get a path to dev_container/modules/"module_name".  We can do this simply
#by getting the absolute path to this makefile.  Note that very old versions of make might not support this line.
ROOT_DEV_MODULE_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

# including the common makefile gives us a handle to the service directory.  This is
# where we will (for now) dump the service log files
include $(TOP_DIR)/tools/Makefile.common
$(SERVICE_DIR) ?= /kb/deployment/services/$(SERVICE)
PID_FILE = $(SERVICE_DIR)/service.pid
ACCESS_LOG_FILE = $(SERVICE_DIR)/log/access.log
ERR_LOG_FILE = $(SERVICE_DIR)/log/error.log

# You can change these if you are putting your tests somewhere
# else or if you are not using the standard .t suffix

# make sure our make test works
.PHONY : test

# default target is all, which compiles the typespec and builds documentation
default: all

all: compile-typespec build-docs

compile-typespec:
	mkdir -p lib/biokbase/$(SERVICE_NAME_PY)
	touch lib/biokbase/__init__.py #do not include code in biokbase/__init__.py
	touch lib/biokbase/$(SERVICE_NAME_PY)/__init__.py 
	mkdir -p lib/javascript/$(SERVICE_NAME)
	compile_typespec \
		--psgi $(SERVICE_PSGI_FILE) \
		--impl Bio::KBase::$(SERVICE_NAME)::$(SERVICE_NAME)Impl \
		--service Bio::KBase::$(SERVICE_NAME)::Service \
		--client Bio::KBase::$(SERVICE_NAME)::Client \
		--py biokbase/$(SERVICE_NAME_PY)/client \
		--js javascript/$(SERVICE_NAME)/Client \
		--url http://kbase.us/services/erdb_service \
		$(SERVICE_NAME).spec lib
	-rm lib/$(SERVICE_NAME)Server.py
	-rm lib/$(SERVICE_NAME)Impl.py
	-rm -r Bio # For some strange reason, compile_typespec always creates this directory in the root dir!

build-docs: compile-typespec
	mkdir -p docs
	pod2html --infile=lib/Bio/KBase/$(SERVICE_NAME)/Client.pm --outfile=docs/$(SERVICE_NAME).html
	rm -f pod2htmd.tmp

# here are the standard KBase test targets (test, test-all, deploy-client, deploy-scripts, & deploy-service)
test: test-client test-scripts

test-all: test-service test-client test-scripts

# will need to fix the host when code is distributed, to point
# to the "official" instance
test-client: test-service
#	$(DEPLOY_RUNTIME)/bin/perl -Ilib -It $(TOP_DIR)/modules/$(SERVICE)/t/runtests.t --serviceName $(SERVICE_NAME) --port $(SERVICE_PORT) --host localhost
# taking this test out for now since it requires a deployed, manually started server.
# testing the client tests the server anyway, so just run the server tests. 

test-scripts:
	echo "This service has no scripts."

test-service:
	$(DEPLOY_RUNTIME)/bin/perl -Ilib -It $(TOP_DIR)/modules/$(SERVICE)/t/runtests.t --serviceName $(SERVICE_NAME) --localServer

# here are the standard KBase deployment targets (deploy, deploy-all, deploy-client, deploy-scripts, & deploy-service)
deploy: deploy-all
	echo "OK... Done deploying $(SERVICE)."

deploy-all: deploy-client deploy-service
	echo "OK... Done deploying ALL artifacts (includes clients, docs, scripts and service) of $(SERVICE)."

deploy-client: deploy-docs deploy-scripts
	mkdir -p $(TARGET)/lib/Bio/KBase/$(SERVICE_NAME)
	mkdir -p $(TARGET)/lib/biokbase/$(SERVICE_NAME_PY)
	mkdir -p $(TARGET)/lib/javascript/$(SERVICE_NAME)
	cp lib/Bio/KBase/$(SERVICE_NAME)/Client.pm $(TARGET)/lib/Bio/KBase/$(SERVICE_NAME)/.
	cp lib/biokbase/$(SERVICE_NAME_PY)/* $(TARGET)/lib/biokbase/$(SERVICE_NAME_PY)/.
	cp lib/javascript/$(SERVICE_NAME)/* $(TARGET)/lib/javascript/$(SERVICE_NAME)/.
	echo "deployed clients of $(SERVICE)."

deploy-scripts:
	echo "This service has no scripts."

deploy-docs:
	mkdir -p $(SERVICE_DIR)/webroot
	cp docs/*.html $(SERVICE_DIR)/webroot/.


# deploys all libraries and scripts needed to start the service
deploy-service: deploy-service-libs deploy-service-scripts

deploy-service-libs:
	mkdir -p $(TARGET)/lib/Bio/KBase/$(SERVICE_NAME)
	cp lib/Bio/KBase/$(SERVICE_NAME)/Service.pm $(TARGET)/lib/Bio/KBase/$(SERVICE_NAME)/.
	cp $(TOP_DIR)/modules/$(SERVICE)/lib/Bio/KBase/$(SERVICE_NAME)/$(SERVICE_NAME)Impl.pm $(TARGET)/lib/Bio/KBase/$(SERVICE_NAME)/.
	cp $(TOP_DIR)/modules/$(SERVICE)/lib/$(SERVICE_PSGI_FILE) $(TARGET)/lib/.
	mkdir -p $(SERVICE_DIR)
	echo "deployed service for $(SERVICE)."

# creates start/stop/reboot scripts and copies them to the deployment target
deploy-service-scripts:
	
	# First create the start script (should be a better way to do this...)
	echo '#!/bin/sh' > ./start_service
	echo "echo starting $(SERVICE) service." >> ./start_service
	echo 'export PERL5LIB=$$PERL5LIB:$(TARGET)/lib' >> ./start_service
	echo 'if [ -z "$$KB_DEPLOYMENT_CONFIG" ]' >> ./start_service
	echo 'then' >> ./start_service
	echo '    export KB_DEPLOYMENT_CONFIG=$(TARGET)/deployment.cfg' >> ./start_service
	echo 'fi' >> ./start_service
	echo 'export KB_SERVICE_NAME=$(SERVICE_CONFIG_NAME)' >> ./start_service
	echo '#uncomment to debug: export STARMAN_DEBUG=1' >> ./start_service
	echo "$(DEPLOY_RUNTIME)/bin/starman --listen :$(SERVICE_PORT) --pid $(PID_FILE) --daemonize \\" >> ./start_service
	echo "  --access-log $(ACCESS_LOG_FILE) \\" >>./start_service
	echo "  --error-log $(ERR_LOG_FILE) \\" >> ./start_service
	echo "  $(TARGET)/lib/$(SERVICE_PSGI_FILE)" >> ./start_service
	echo "echo $(SERVICE) service is listening on port $(SERVICE_PORT)." >> ./start_service
	
	# Second, create a debug start script that is not daemonized
	echo '#!/bin/sh' > ./debug_start_service
	echo 'export PERL5LIB=$$PERL5LIB:$(TARGET)/lib' >> ./debug_start_service
	echo 'if [ -z "$$KB_DEPLOYMENT_CONFIG" ]' >> ./debug_start_service
	echo 'then' >> ./debug_start_service
	echo '    export KB_DEPLOYMENT_CONFIG=$(TARGET)/deployment.cfg' >> ./debug_start_service
	echo 'fi' >> ./debug_start_service
	echo 'export KB_SERVICE_NAME=$(SERVICE_CONFIG_NAME)' >> ./debug_start_service
	echo 'export STARMAN_DEBUG=1' >> ./debug_start_service
	echo "$(DEPLOY_RUNTIME)/bin/starman --listen :$(SERVICE_PORT) --workers 1 \\" >> ./debug_start_service
	echo "    $(TARGET)/lib/$(SERVICE_PSGI_FILE)" >> ./debug_start_service
	
	# Third create the stop script (should be a better way to do this...)
	echo '#!/bin/sh' > ./stop_service
	echo "echo trying to stop $(SERVICE) service." >> ./stop_service
	echo "pid_file=$(PID_FILE)" >> ./stop_service
	echo "if [ ! -f \$$pid_file ] ; then " >> ./stop_service
	echo "  echo No pid file: \$$pid_file found for service $(SERVICE)." >> ./stop_service
	echo "  exit 1" >> ./stop_service
	echo "fi" >> ./stop_service
	echo "pid=\$$(cat \$$pid_file)" >> ./stop_service
	echo "kill \$$pid" >> ./stop_service
	
	# Finally create a script to reboot the service by stopping, redeploying the service, and starting again
	echo '#!/bin/sh' > ./reboot_service
	echo '# auto-generated script to stop the service, redeploy service implementation, and start the servce' >> ./reboot_service
	echo "./stop_service\ncd $(ROOT_DEV_MODULE_DIR)\nmake deploy-service-libs\ncd -\n./start_service" >> ./reboot_service
	
	# Actually run the deployment of these scripts
	chmod +x start_service stop_service reboot_service debug_start_service
	mkdir -p $(SERVICE_DIR)
	mkdir -p $(SERVICE_DIR)/log
	cp start_service $(SERVICE_DIR)/
	cp debug_start_service $(SERVICE_DIR)/
	cp stop_service $(SERVICE_DIR)/
	cp reboot_service $(SERVICE_DIR)/

undeploy:
	rm -rfv $(SERVICE_DIR)
	rm -rfv $(TARGET)/lib/Bio/KBase/$(SERVICE_NAME)
	rm -rfv $(TARGET)/lib/$(SERVICE_PSGI_FILE)
	rm -rfv $(TARGET)/lib/biokbase/$(SERVICE_NAME_PY)
	rm -rfv $(TARGET)/lib/javascript/$(SERVICE_NAME)
	rm -rfv $(TARGET)/docs/$(SERVICE_NAME)
	echo "OK ... Removed all deployed files."

# remove files generated by building the service
clean:
	rm -f lib/Bio/KBase/$(SERVICE_NAME)/Client.pm
	rm -f lib/Bio/KBase/$(SERVICE_NAME)/Service.pm
	rm -f lib/$(SERVICE_PSGI_FILE)
	rm -rf lib/biokbase
	rm -rf lib/javascript
	rm -rf docs
	rm -f start_service stop_service reboot_service debug_start_service


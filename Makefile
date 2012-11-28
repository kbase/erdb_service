# configurable variables
SERVICE = ERDBService
SERVICE_PORT = 7055 # temporary until assigned a permanent port

#standalone variables, replaced when run via /kb/dev_container/Makefile
TARGET ?= /kb/deployment
DEPLOY_RUNTIME ?= /kb/runtime

TOP_DIR = ../..
include $(TOP_DIR)/tools/Makefile.common
PID_FILE = $(SERVICE_DIR)/service.pid
LOG_DIR = $(SERVICE_DIR)/log
ACCESS_LOG_FILE = $(LOG_DIR)/access.log
ERR_LOG_FILE = $(LOG_DIR)/error.log

all:

deploy: deploy-client 

#redeploy: clean deploy

.PHONY: test

test:
	nosetests --exe -P -w test

deploy-client:
	cp -vr ./lib/* $(TARGET)/lib/
	
deploy-server: deploy-client
	echo '#!/bin/sh' > ./start_service
	echo "echo starting $(SERVICE) services." >> ./start_service
	echo 'export PERL5LIB=$(TARGET)/lib:$$PERL5LIB' >> ./start_service
	echo "$(DEPLOY_RUNTIME)/bin/starman --listen :$(SERVICE_PORT) --pid $(PID_FILE) --daemonize \\" >> ./start_service
	echo "  --access-log $(ACCESS_LOG_FILE) \\" >>./start_service
	echo "  --error-log $(ERR_LOG_FILE) \\" >> ./start_service
	echo "  $(TARGET)/lib/$(SERVICE).psgi" >> ./start_service
	echo "echo $(SERVICE) service is listening on port $(SERVICE_PORT).\n" >> ./start_service
	echo '#!/bin/sh' > ./stop_service
	echo "echo trying to stop $(SERVICE) service." >> ./stop_service
	echo "pid_file=$(PID_FILE)" >> ./stop_service
	echo "if [ ! -f \$$pid_file ] ; then " >> ./stop_service
	echo "\techo \"No pid file: \$$pid_file found for service $(SERVICE).\"\n\texit 1\nfi" >> ./stop_service
	echo "pid=\$$(cat \$$pid_file)\nkill \$$pid\n" >> ./stop_service
	chmod +x start_service stop_service
	mkdir -p $(SERVICE_DIR)
	mkdir -p $(SERVICE_DIR)/log
	#cp -rv lib/* $(SERVICE_DIR)/lib
	cp -v start_service $(SERVICE_DIR)/start_service
	cp -v stop_service $(SERVICE_DIR)/stop_service
	echo "OK ... Done deploying $(SERVICE) services."
	
deploy-docs:
	pod2html --title $(SERVICE) --infile lib/Bio/KBase/$(SERVICE)/$(SERVICE)Impl.pm --outfile doc/$(SERVICE).html
	
clean:
	rm -rfv $(SERVICE_DIR)
	rm start_service stop_service
	#echo "OK ... Removed all deployed files."
	#NOTE this doesn't clean up the /lib dir
	


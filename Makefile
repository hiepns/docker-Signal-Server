MAKEFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MAKEFILE_DIR  := $(patsubst %/,%,$(dir $(MAKEFILE_PATH)))

S3_ENDPOINT           := http://signal-minio:9000
S3_ATTACHMENTS_BUCKET := signal-attachments-buu
S3_PROFILES_BUCKET    := signal-profiles-buu

DOCKER_PREFIX := $(shell echo $(notdir $(MAKEFILE_DIR)) | tr A-Z a-z)

ifeq ($(OS),Windows_NT)
	OS_ESC_PREFIX=/
else
	OS_ESC_PREFIX=
endif

-include .env

.PHONY: all help up start down stop provision provision-s3
all: help

help:
	@echo "make up		- start docker-compose"
	@echo "make down	- stop docker-compose"
	@echo "make provision	- create S3 buckets"

$(MAKEFILE_DIR)/.env:
	@echo ".env file was not found, creating with defaults"
	cp $(MAKEFILE_DIR)/.env.dist $(MAKEFILE_DIR)/.env

$(MAKEFILE_DIR)/postgresql/data:
	mkdir -p $(MAKEFILE_DIR)/postgresql/data

up start: | $(MAKEFILE_DIR)/.env $(MAKEFILE_DIR)/postgresql/data
	cd $(MAKEFILE_DIR) && docker-compose up --detach --remove-orphans

down stop: | $(MAKEFILE_DIR)/.env $(MAKEFILE_DIR)/postgresql/data
	cd $(MAKEFILE_DIR) && docker-compose stop

provision: | $(MAKEFILE_DIR)/.env $(MAKEFILE_DIR)/postgresql/data
	docker run --rm -it --network $(DOCKER_PREFIX)_default \
	    -v $(OS_ESC_PREFIX)$(MAKEFILE_DIR):/mnt --entrypoint '' minio/mc \
	    /bin/sh -c "/usr/bin/mc config host add myminio $(S3_ENDPOINT) $(MINIO_ACCESS_KEY) $(MINIO_SECRET_KEY) && \
	        /usr/bin/mc rm -r --force myminio/$(S3_ATTACHMENTS_BUCKET); \
	        /usr/bin/mc rm -r --force myminio/$(S3_PROFILES_BUCKET); \
	        /usr/bin/mc mb myminio/$(S3_ATTACHMENTS_BUCKET) && \
	        /usr/bin/mc mb myminio/$(S3_PROFILES_BUCKET) && \
	        /usr/bin/mc policy public myminio/$(S3_ATTACHMENTS_BUCKET) && \
	        /usr/bin/mc policy public myminio/$(S3_PROFILES_BUCKET)"

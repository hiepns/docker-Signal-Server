MAKEFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MAKEFILE_DIR  := $(patsubst %/,%,$(dir $(MAKEFILE_PATH)))

S3_ENDPOINT           := http://signal-minio:9000
S3_ATTACHMENTS_BUCKET := signal-attachments-buu
S3_PROFILES_BUCKET    := signal-profiles-buu
REGISTRY              := registry.domain.ru/namespace/

DOCKER_PREFIX := $(shell echo $(notdir $(MAKEFILE_DIR)) | tr A-Z a-z)

ifeq ($(OS),Windows_NT)
	OS_ESC_PREFIX=/
else
	OS_ESC_PREFIX=
endif

-include .env

.PHONY: all help up start down stop provision status build-server build-turn
.PHONY: publish-server publish-turn helm
all: help

help:
	@echo "make up		- start docker-compose"
	@echo "make down	- stop docker-compose"
	@echo "make provision	- create S3 buckets"
	@echo "make status	- show containers state"
	@echo "make build-server	- build signal server container"
	@echo "make build-turn	- build turn server container"
	@echo "make publish-server	- publish signal server container"
	@echo "make publish-turn	- publish turn server container"
	@echo "make helm	- create first release of Helm Chart"
	@echo "make upgrade	- create next release of Helm Chart"

$(MAKEFILE_DIR)/.env:
	@echo ".env file was not found, creating with defaults"
	cp $(MAKEFILE_DIR)/.env.dist $(MAKEFILE_DIR)/.env

$(MAKEFILE_DIR)/signalserver/Signal-Server/config/Signal.yml:
	$(error signalserver/Signal-Server/config/Signal.yml not found. Create it according to README.md)

$(MAKEFILE_DIR)/postgresql/data:
	mkdir -p $(MAKEFILE_DIR)/postgresql/data

up start: | $(MAKEFILE_DIR)/.env $(MAKEFILE_DIR)/postgresql/data $(MAKEFILE_DIR)/signalserver/Signal-Server/config/Signal.yml
	cd $(MAKEFILE_DIR) && docker-compose up -d --remove-orphans

down stop: | $(MAKEFILE_DIR)/.env $(MAKEFILE_DIR)/postgresql/data $(MAKEFILE_DIR)/signalserver/Signal-Server/config/Signal.yml
	cd $(MAKEFILE_DIR) && docker-compose stop

provision: | $(MAKEFILE_DIR)/.env $(MAKEFILE_DIR)/postgresql/data $(MAKEFILE_DIR)/signalserver/Signal-Server/config/Signal.yml
	docker run --rm -it --network $(DOCKER_PREFIX)_default \
	    -v $(OS_ESC_PREFIX)$(MAKEFILE_DIR):/mnt --entrypoint '' minio/mc \
	    /bin/sh -c "/usr/bin/mc config host add myminio $(S3_ENDPOINT) $(MINIO_ACCESS_KEY) $(MINIO_SECRET_KEY) && \
	        /usr/bin/mc mb myminio/$(S3_ATTACHMENTS_BUCKET) && \
	        /usr/bin/mc mb myminio/$(S3_PROFILES_BUCKET) && \
	        /usr/bin/mc policy set public myminio/$(S3_ATTACHMENTS_BUCKET) && \
	        /usr/bin/mc policy set public myminio/$(S3_PROFILES_BUCKET)"

status: | $(MAKEFILE_DIR)/.env $(MAKEFILE_DIR)/postgresql/data $(MAKEFILE_DIR)/signalserver/Signal-Server/config/Signal.yml
	cd $(MAKEFILE_DIR) && docker-compose ps

build-server:
	docker build -t $(REGISTRY)signal-server signalserver

publish-server:
	docker push $(REGISTRY)signal-server:latest

build-turn:
	docker build -t $(REGISTRY)signal-turn turn

publish-turn:
	docker push $(REGISTRY)signal-turn:latest

$(MAKEFILE_DIR)/k8s/Signal.yml: | $(MAKEFILE_DIR)/signalserver/Signal-Server/config/Signal.yml
	ln -s $(MAKEFILE_DIR)/signalserver/Signal-Server/config/Signal.yml $(MAKEFILE_DIR)/k8s/Signal.yml

$(MAKEFILE_DIR)/k8s/010-create_databases.sh:
	ln -s $(MAKEFILE_DIR)/postgresql/010-create_databases.sh $(MAKEFILE_DIR)/k8s/010-create_databases.sh

helm: | $(MAKEFILE_DIR)/.env $(MAKEFILE_DIR)/k8s/Signal.yml $(MAKEFILE_DIR)/k8s/010-create_databases.sh
	helm install ./k8s -n signal --debug --set imagePullSecrets=$(IMAGE_PULL_SECRETS) \
	    --set externalIp=$(EXTERNAL_IP) --set registry=$(REGISTRY) --set turn.secret=$(TURN_SECRET) \
	    --set turn.realm=$(TURN_REALM) --set postgres.dbPassword=$(POSTGRES_PASSWORD) \
	    --set minio.accessKey=$(MINIO_ACCESS_KEY) --set minio.secretKey=$(MINIO_SECRET_KEY) \
	    --set minio.bucketProfiles=$(S3_PROFILES_BUCKET) \
	    --set minio.bucketAttachments=$(S3_ATTACHMENTS_BUCKET) \
	    --set minio.endpointProfiles=$(PROFILES_ENDPOINT) \
	    --set minio.endpointAttachments=$(ATTACHMENTS_ENPOINT) \
	    --set signal.domain=$(SIGNAL_DOMAIN)

upgrade: | $(MAKEFILE_DIR)/.env $(MAKEFILE_DIR)/k8s/Signal.yml $(MAKEFILE_DIR)/k8s/010-create_databases.sh
	helm upgrade signal ./k8s --debug --set imagePullSecrets=$(IMAGE_PULL_SECRETS) \
	    --set externalIp=$(EXTERNAL_IP) --set registry=$(REGISTRY) --set turn.secret=$(TURN_SECRET) \
	    --set turn.realm=$(TURN_REALM) --set postgres.dbPassword=$(POSTGRES_PASSWORD) \
	    --set minio.accessKey=$(MINIO_ACCESS_KEY) --set minio.secretKey=$(MINIO_SECRET_KEY) \
	    --set minio.bucketProfiles=$(S3_PROFILES_BUCKET) \
	    --set minio.bucketAttachments=$(S3_ATTACHMENTS_BUCKET) \
	    --set minio.endpointProfiles=$(PROFILES_ENDPOINT) \
	    --set minio.endpointAttachments=$(ATTACHMENTS_ENPOINT) \
	    --set signal.domain=$(SIGNAL_DOMAIN)

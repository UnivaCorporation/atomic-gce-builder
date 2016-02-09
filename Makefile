#___INFO__MARK_BEGIN__
#############################################################################
#
#  This code is the Property, a Trade Secret and the Confidential Information
#  of Univa Corporation.
#
#  Copyright Univa Corporation. All Rights Reserved. Access is Restricted.
#
#  It is provided to you under the terms of the
#  Univa Term Software License Agreement.
#
#  If you have any questions, please contact our Support Department.
#
#  www.univa.com
#
###########################################################################
#___INFO__MARK_END__
IMAGE_NAME:=atomic-gce-builder
BUILD_IMAGE:=local/$(IMAGE_NAME):latest
BUILD_CONTAINER:=gce-builder
BUILD_DIR:=build

ATOMIC_URL:=https://download.fedoraproject.org/pub/alt/atomic/stable/Cloud-Images/x86_64/Images
ATOMIC_BASE_NAME:=Fedora-Cloud-Atomic-23-20160127.2.x86_64.raw
ATOMIC_NAME:=$(ATOMIC_BASE_NAME).xz
ATOMIC_TGZ_NAME:=$(ATOMIC_BASE_NAME).tar.gz

PUSH_USER?=$(shell whoami)
PUSH_TAG?=$(PUSH_USER)-$(shell git describe --long --dirty --abbrev=10 --always)
PUSH_REGISTRY_NAME?=gcr.io/navops-devel

MY_ID:=$(shell id -u)
MY_GROUP:=$(shell id -g)


.PHONY: all builder push push-latest build-disk clean clean-all

all: builder 

builder:
	docker build --rm -t $(BUILD_IMAGE) .

$(BUILD_DIR):
	mkdir -p $@

$(BUILD_DIR)/$(ATOMIC_NAME): | $(BUILD_DIR)
	curl -L $(ATOMIC_URL)/$(ATOMIC_NAME) > $@

$(BUILD_DIR)/$(ATOMIC_BASE_NAME): $(BUILD_DIR)/$(ATOMIC_NAME)
	xz --decompress -k $^

build-disk: $(BUILD_DIR)/$(ATOMIC_TGZ_NAME)
$(BUILD_DIR)/$(ATOMIC_TGZ_NAME): $(BUILD_DIR)/$(ATOMIC_BASE_NAME)
	cd $(@D) && tar -Szcf $(@F) $(^F)

push:
	docker tag -f $(BUILD_IMAGE) $(PUSH_REGISTRY_NAME)/$(IMAGE_NAME):$(PUSH_TAG)
	docker tag -f $(BUILD_IMAGE) $(PUSH_REGISTRY_NAME)/$(IMAGE_NAME):$(PUSH_USER)
	gcloud docker push $(PUSH_REGISTRY_NAME)/$(IMAGE_NAME):$(PUSH_TAG)
	gcloud docker push $(PUSH_REGISTRY_NAME)/$(IMAGE_NAME):$(PUSH_USER)

push-latest:
	docker tag -f $(BUILD_IMAGE) $(PUSH_REGISTRY_NAME)/$(IMAGE_NAME)
	gcloud docker push $(PUSH_REGISTRY_NAME)/$(IMAGE_NAME)

clean:
	rm -rf build

clean-all: clean
	docker rmi $(BUILD_IMAGE)

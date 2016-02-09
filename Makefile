#___INFO__MARK_BEGIN__
#############################################################################
# The MIT License (MIT)
#  Copyright (c) 2016 Univa, Corp
#
# Permission is hereby granted, free of charge, to any person obtaining a copy 
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is 
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.
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

ROOT_PATH := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

all: build test

build:
	PACKER_LOG=1 CHECKPOINT_DISABLE=1 $(ROOT_PATH)main.sh build

test:
	PACKER_LOG=1 CHECKPOINT_DISABLE=1 $(ROOT_PATH)main.sh test

vagrant-up:
	$(ROOT_PATH)main.sh vagrant-up

vagrant-down:
	$(ROOT_PATH)main.sh vagrant-down

clean:
	sudo rm -f $(ROOT_PATH)output-vagrant/seed.img
	rm -rf $(ROOT_PATH)output*
	rm -f $(ROOT_PATH)*.log
	rm -rf $(ROOT_PATH)packer_cache

.PHONY: build test vagrant-up vagrant-down clean

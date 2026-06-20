PACKER_FILES := $(shell find ./packer -type f -name '*.pkr.hcl')
DIR := $(shell pwd)
IMAGES_DIR := $(DIR)/images
INCUS_IMAGE := isp-base
INCUS_EXPORT_DIR := $(IMAGES_DIR)/x86_64/lxc

.PHONY: build images clean $(PACKER_FILES)

build: $(PACKER_FILES)

$(PACKER_FILES):
	cd $(@D) && packer build $(@F) && cd ${DIR}

clean:
	rm -rf $(IMAGES_DIR)
	-incus image delete $(INCUS_IMAGE)

images:
	$(MAKE) clean
	$(MAKE) build
	mkdir -p $(INCUS_EXPORT_DIR)
	incus image export $(INCUS_IMAGE) $(INCUS_EXPORT_DIR)/$(INCUS_IMAGE)

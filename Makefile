ARCH ?= aarch64
PLATFORM ?= qemu
HVISOR_BRANCH ?= hvisor-dev
KDIR ?= ~/linux

DEV_DIR = $(shell pwd)
IMG_DIR = $(DEV_DIR)/images/$(ARCH)/$(PLATFORM)
PLAT_DIR = $(DEV_DIR)/platform/$(ARCH)/$(PLATFORM)

export DEV_DIR, IMG_DIR, PLAT_DIR

ifeq ($(ARCH),aarch64)
	TOOL_ARCH := arm64
else ifeq ($(ARCH),riscv64)
	TOOL_ARCH := riscv
else ifeq ($(ARCH),loongarch64)
	TOOL_ARCH := loongarch64
else
	# Error out if an unsupported ARCH value is provided.
	$(error Unsupported ARCH value: $(ARCH))
endif

include $(PLAT_DIR)/platform.mk

hvisor_ko :=  $(DEV_DIR)/hvisor-tool/driver/hvisor.ko
hvisor_tool := $(DEV_DIR)/hvisor-tool/tools/hvisor

FS_FILE_LIST += $(hvisor_ko) $(hvisor_tool)

HVISOR_COMPILE_CMD := cd hvisor && git checkout $(HVISOR_BRANCH) && make

.PHONY: all run submodules hvisor tool images clean fs copy-hvisor-bin

all: hvisor tool images

run: all
	$(HVISOR_RUNCMD)

update:
	git submodule update --init --recursive

hvisor:
	@current_branch="$(shell cd hvisor && git branch --show-current 2>/dev/null)"; \
	if [ "$${current_branch}" != "$(HVISOR_BRANCH)" ]; then \
		cd hvisor && git checkout $(HVISOR_BRANCH) && $(MAKE) && cd ..; \
	else \
		$(MAKE) -C hvisor; \
	fi;

tool:
	$(MAKE) -C hvisor-tool ARCH=$(TOOL_ARCH) KDIR=$(KDIR)

clean:
	$(MAKE) -C hvisor clean
	$(MAKE) -C hvisor-tool clean KDIR=$(KDIR)
	rm -f hvisor/hvisor.bin $(IMG_DIR)/hvisor.bin

images: hvisor hvisor-tool filesystem

filesystem: copy-hvisor-bin
	@if ! [ -f $(FSIMG1) ]; then \
		echo "$(FSIMG1) does not exist, please check the file path or create the file system image first."; \
	fi && \
	mkdir -p $(IMG_DIR)/fs
	sudo umount $(IMG_DIR)/fs || true
	sudo mount $(FSIMG1) $(IMG_DIR)/fs && \
	sudo mkdir -p $(IMG_DIR)/fs/hvisor && \
	sudo cp $(FS_FILE_LIST) $(IMG_DIR)/fs/hvisor
	sudo echo -e "cd hvisor\ninsmod $(notdir $(hvisor_ko))\n./hvisor zone start $(notdir $(zone1_config))" > start.sh.tmp && \
		sudo chmod +x start.sh.tmp && \
		sudo mv start.sh.tmp $(IMG_DIR)/fs/start.sh
	sudo umount $(IMG_DIR)/fs || true
	rm -rf $(IMG_DIR)/fs

copy-hvisor-bin: hvisor
	cp hvisor/hvisor.bin $(IMG_DIR)/hvisor.bin
VM_NAME = dogebox-$(shell date +%s)
T6_WORK_DIR = nixos-arm64

nanopc-T6:
	@echo "Generating nanopc-T6 image..."
	@nix build .#t6 -L --print-out-paths

nanopc-T6-uboot:
	#	NIXPKGS_ALLOW_UNFREE=1 nix-build -E 'with (import <nixpkgs>{}); pkgsCross.aarch64-multiplatform.ubootNanoPCT6'
	@echo "Building uboot for nanopc-T6..."
	@NIXPKGS_ALLOW_UNFREE=1 nix build .#t6-uboot -L --print-out-paths --impure

nanopc-T6-sd: nanopc-T6-uboot
	@echo "Generating nanopc-T6 image..."
	UBOOT_ROOT=$$(NIXPKGS_ALLOW_UNFREE=1 nix-build -E 'with (import <nixpkgs>{}); pkgsCross.aarch64-multiplatform.ubootNanoPCT6' | grep -o '/nix/store/.*uboot-nanopc-t6-rk3588_defconfig-.*');\
	echo $$UBOOT_ROOT; \
	mkdir -vp $(T6_WORK_DIR); \
	umask 122; \
	cp -v $$UBOOT_ROOT/idbloader.img $(T6_WORK_DIR)/idbloader.img   && chmod 644 $(T6_WORK_DIR)/idbloader.img; \
	cp -v $$UBOOT_ROOT/u-boot.itb    $(T6_WORK_DIR)/uboot.img       && chmod 644 $(T6_WORK_DIR)/uboot.img; \
	DISK_IMAGE_DIR=$$(nix build .#t6 -L --print-out-paths | grep -o '.*\.img$$'); \
	echo $$DISK_IMAGE_DIR; \
	bash bin/extract-fs-from-disk-image.sh $$DISK_IMAGE_DIR/dogebox*-t6.img $(T6_WORK_DIR); \
	if [[ ! -f $(T6_WORK_DIR)/parameter.txt ]]; then cp templates/parameter.txt $(T6_WORK_DIR)/parameter.txt; fi; \
	bash bin/make-sd-image.sh

pve-x86_64:
	@echo "Generating Proxmox LXC..."
	@nixos-generate -c nix/pve-builder.nix -f proxmox-lxc

qemu:
	@echo "Generating QEMU qcow2..."
	@nixos-generate -c nix/qemu-builder.nix -f qcow

raw:
	@echo "Generating raw image..."
	@nixos-generate -c nix/default-builder.nix -f raw

virtualbox-x86_64:
	@echo "Generating VirtualBox OVA..."
	@nix build .#vbox-x86_64 -L --print-out-paths

virtualbox-x86_64-launch: virtualbox
	@echo "Importing and launching the VirtualBox VM..."
	# Capture the generated OVA path from the nixos-generate output
	@nix build .#vbox-x86_64 -L --print-out-paths

	OVA_FILE=$$(nixos-generate -c nix/vbox-builder.nix -f virtualbox | grep -o '.*\.ova$$'); \
	BRIDGE_ADAPTER=$$(VBoxManage list bridgedifs | grep '^Name:' | head -n1 | awk '{print $$2}'); \
	VBoxManage import $$OVA_FILE --vsys 0 --vmname "$(VM_NAME)" && \
	VBoxManage modifyvm "$(VM_NAME)" --nic1 bridged --bridgeadapter1 $$BRIDGE_ADAPTER && \
	VBoxManage startvm "$(VM_NAME)"

vmware:
	@echo "Generating VMWare VMDK..."
	@nixos-generate -c nix/vmware-builder.nix -f vmware

.PHONY: nanopc-T6 nanopc-T6-sd nanopc-T6-uboot pve qemu raw virtualbox virtualbox-launch vmware


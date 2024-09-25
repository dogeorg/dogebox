VM_NAME = dogebox-$(shell date +%s)

nanopc-T6:
	@echo "Generating nanopc-T6 image..."
	@nixos-generate -c nix/nanopc-T6-builder.nix -f raw

pve:
	@echo "Generating Proxmox LXC..."
	@nixos-generate -c nix/pve-builder.nix -f proxmox-lxc

qemu:
	@echo "Generating QEMU qcow2..."
	@nixos-generate -c nix/qemu-builder.nix -f qcow

raw:
	@echo "Generating raw image..."
	@nixos-generate -c nix/default-builder.nix -f raw

virtualbox:
	@echo "Generating VirtualBox OVA..."
	@nixos-generate -c nix/vbox-builder.nix -f virtualbox

virtualbox-launch: virtualbox
	@echo "Importing and launching the VirtualBox VM..."
	# Capture the generated OVA path from the nixos-generate output
	OVA_FILE=$$(nixos-generate -c nix/vbox-builder.nix -f virtualbox | grep -o '.*\.ova$$'); \
	BRIDGE_ADAPTER=$$(VBoxManage list bridgedifs | grep '^Name:' | head -n1 | awk '{print $$2}'); \
	VBoxManage import $$OVA_FILE --vsys 0 --vmname "$(VM_NAME)" && \
	VBoxManage modifyvm "$(VM_NAME)" --nic1 bridged --bridgeadapter1 $$BRIDGE_ADAPTER && \
	VBoxManage startvm "$(VM_NAME)"

vmware:
	@echo "Generating VMWare VMDK..."
	@nixos-generate -c nix/vmware-builder.nix -f vmware

.PHONY: pve qemu raw virtualbox virtualbox-launch vmware

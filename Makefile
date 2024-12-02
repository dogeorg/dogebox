VM_NAME = dogebox-$(shell date +%s)

iso-aarch64:
	@echo "Generating aarch64 ISO image..."
	@nix build .#iso-aarch64 -L --print-out-paths

iso-x86_64:
	@echo "Generating x86_64 ISO image..."
	@nix build .#iso-x86_64 -L --print-out-paths

nanopc-T6:
	@echo "Generating nanopc-T6 image..."
	@nix build .#t6 -L --print-out-paths

pve-aarch64:
	@echo "Generating aarch64 Proxmox LXC..."
	@nix build .#pve-aarch64 -L --print-out-paths

pve-x86_64:
	@echo "Generating x86_64 Proxmox LXC..."
	@nix build .#pve-x86_64 -L --print-out-paths

qemu-aarch64:
	@echo "Generating aarch64 QEMU qcow2..."
	@nix build .#qemu-aarch64 -L --print-out-paths

qemu-x86_64:
	@echo "Generating x86_64 QEMU qcow2..."
	@nix build .#qemu-x86_64 -L --print-out-paths

raw-aarch64:
	@echo "Generating aarch64 raw image..."
	@nix build .#raw-aarch64 -L --print-out-paths

raw-x86_64:
	@echo "Generating x86_64 raw image..."
	@nix build .#raw-x86_64 -L --print-out-paths

virtualbox-aarch64:
	@echo "Generating aarch64 Virtualbox OVA..."
	@nix build .#vbox-aarch64 -L --print-out-paths

virtualbox-x86_64:
	@echo "Generating x86_64 VirtualBox OVA..."
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

vm-aarch64:
	@echo "Generating aarch64 VM image..."
	@nix build .#vm-aarch64 -L --print-out-paths

vm-x86_64:
	@echo "Generating x86_64 VM image..."
	@nix build .#vm-x86_64 -L --print-out-paths

vmware-aarch64:
	@echo "Generating aarch64 VMWare VMDK..."
	@nix build .#vmware-aarch64 -L --print-out-paths

vmware-x86_64:
	@echo "Generating x86_64 VMWare VMDK..."
	@nix build .#vmware-x86_64 -L --print-out-paths



.PHONY: pve qemu raw virtualbox virtualbox-launch vmware

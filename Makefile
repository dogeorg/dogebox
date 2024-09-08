VM_NAME = dogebox-$(shell date +%s)

virtualbox:
	@echo "Generating VirtualBox OVA..."
	@nixos-generate -c nix/vbox.nix -f virtualbox

virtualbox-launch: virtualbox
	@echo "Importing and launching the VirtualBox VM..."
	# Capture the generated OVA path from the nixos-generate output
	OVA_FILE=$$(nixos-generate -c nix/vbox.nix -f virtualbox | grep -o '.*\.ova$$'); \
	BRIDGE_ADAPTER=$$(VBoxManage list bridgedifs | grep '^Name:' | head -n1 | awk '{print $$2}'); \
	VBoxManage import $$OVA_FILE --vsys 0 --vmname "$(VM_NAME)" && \
	VBoxManage modifyvm "$(VM_NAME)" --nic1 bridged --bridgeadapter1 $$BRIDGE_ADAPTER && \
	VBoxManage startvm "$(VM_NAME)"

.PHONY: virtualbox virtualbox-launch

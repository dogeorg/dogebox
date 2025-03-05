VM_NAME = dogebox-$(shell date +%s)

t6:
	@nix build .#t6 -L --print-out-paths

iso-aarch64:
	@nix build .#iso-aarch64 -L --print-out-paths

iso-x86_64:
	@nix build .#iso-x86_64 -L --print-out-paths

qemu-aarch64:
	@nix build .#qemu-aarch64 -L --print-out-paths

qemu-x86_64:
	@nix build .#qemu-x86_64 -L --print-out-paths

vbox-x86_64:
	@nix build .#vbox-x86_64 -L --print-out-paths

vm-x86_64:
	@nix build .#vm-x86_64 -L --print-out-paths

.PHONY: t6 iso-aarch64 iso-x86_64 qemu-aarch64 qemu-x86_64 vbox-x86_64 vm-x86_64


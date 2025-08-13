SHELL := /bin/bash

.PHONY: all user venv pkgs activate run update groups motd vnc
all: run

run:
	sudo bash scripts/05_system_update.sh
	sudo bash scripts/06_groups_users.sh
	sudo bash scripts/10_create_global_venv.sh
	sudo bash scripts/20_install_packages.sh
	sudo bash scripts/25_motd_setup.sh
	sudo bash scripts/30_shell_activation.sh
	sudo bash scripts/35_vnc_config.sh

update:
	sudo bash scripts/05_system_update.sh

groups:
	sudo bash scripts/06_groups_users.sh

venv:
	sudo bash scripts/10_create_global_venv.sh

pkgs:
	sudo bash scripts/20_install_packages.sh

motd:
	sudo bash scripts/25_motd_setup.sh

activate:
	sudo bash scripts/30_shell_activation.sh

vnc:
	sudo bash scripts/35_vnc_config.sh
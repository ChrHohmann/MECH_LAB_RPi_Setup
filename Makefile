## Makefile
```makefile
SHELL := /bin/bash

.PHONY: all user venv pkgs activate run
all: run

run:
	sudo bash scripts/99_run_all.sh

user:
	sudo bash scripts/00_add_user_stud.sh

venv:
	sudo bash scripts/10_create_global_venv.sh

pkgs:
	sudo bash scripts/20_install_packages.sh

activate:
	sudo bash scripts/30_shell_activation.sh

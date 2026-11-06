SHELL := /bin/bash
.DEFAULT_GOAL := help

TEAM ?=

.PHONY: help validate team-up team-down

help:
	@echo "Usage:"
	@echo "  make team-up TEAM=lab-team-03"
	@echo "  make team-down TEAM=lab-team-03"

validate:
	@[[ "$(TEAM)" =~ ^lab-team-[0-9]{2}$$ ]] || { echo "ERROR: Invalid TEAM"; exit 1; }

team-up: validate
	@echo "Provisioning sandbox: $(TEAM)"
	@bash scripts/create-vm.sh "$(TEAM)"
	@bash scripts/create-wireguard.sh "$(TEAM)"
	@bash scripts/create-nomad.sh "$(TEAM)"
	@bash scripts/create-s3-bucket.sh "$(TEAM)"
	@bash scripts/create-postgres-role.sh "$(TEAM)"
	@bash scripts/create-postgres.sh "$(TEAM)"
	@echo "STATUS: All provisioning scripts executed"

team-down: validate
	@echo "Teardown requested: $(TEAM)"
	@bash scripts/delete-vm.sh "$(TEAM)" --confirm
	@bash scripts/delete-wireguard.sh "$(TEAM)" --confirm
	@bash scripts/delete-nomad.sh "$(TEAM)" --confirm
	@bash scripts/delete-s3-bucket.sh "$(TEAM)" --confirm
	@bash scripts/delete-postgres.sh "$(TEAM)" --confirm
	@echo "STATUS: All teardown scripts executed"

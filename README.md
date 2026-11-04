Intern Sandbox Automation

Automated provisioning and teardown of isolated intern development environments using Infrastructure as Code (IaC) and configuration management.

Overview

This project aims to replace manual sandbox setup with a secure, repeatable workflow for creating and removing team-specific infrastructure.

The target commands are:

make team-up TEAM=lab-team-03
make team-down TEAM=lab-team-03

The automation will manage virtual machines, VPN access, database users, and object storage while protecting shared infrastructure.

Status: Local VM provisioning and connectivity validation completed. Full lifecycle automation is in progress.

Technology Stack

Technology	Purpose
Terraform	Infrastructure provisioning
Ansible	Configuration management
QEMU/KVM	Virtual machine deployment
Cloud-init	Automated VM initialization
Ubuntu / WSL2	Local development environment
GNU Make	Automation command interface
WireGuard	Secure VPN connectivity
Nomad	Workload orchestration
PostgreSQL	Team-specific databases
S3-compatible storage	Isolated object storage

WireGuard, Nomad, PostgreSQL, and S3 integration are planned.

Completed Work

Infrastructure Setup

* Installed and verified Terraform and QEMU.
* Checked virtualization capabilities and system resources.
* Downloaded and validated the Ubuntu 22.04 cloud image.
* Created a 20 GiB QCOW2 virtual disk.

VM Provisioning

* Generated SSH ED25519 authentication keys.
* Configured cloud-init initialization files.
* Created a cloud-init seed image.
* Successfully booted the lab-team-03 Ubuntu VM.

Connectivity Validation

* Established SSH public-key authentication.
* Verified VM access through localhost port forwarding.
* Successfully validated Ansible connectivity.

Repository Security

* Configured .gitignore to exclude credentials, VM images, Terraform state, and generated files.
* Documented provisioning procedures, validation results, safety requirements, and teardown plans.

Automation Workflow

Provisioning — team-up

1. Validate team identity.
2. Provision isolated compute resources.
3. Configure networking and VPN access.
4. Create scoped database users and storage.
5. Validate resource availability and permissions.

Teardown — team-down

1. Verify resource ownership.
2. Remove team workloads and VPN access.
3. Delete team-specific database and storage resources.
4. Remove VM disks and networking resources.
5. Verify complete cleanup without affecting shared infrastructure.

Validation Results

Test	Result
Ubuntu image validation	Passed
Cloud-init seed generation	Passed
QCOW2 disk creation	Passed
VM boot	Passed
SSH authentication	Passed
Ansible connectivity	Passed
End-to-end provisioning	Pending
Automated teardown	Pending
Resource cleanup verification	Pending

Security Considerations

* All testing is restricted to the local sandbox.
* No production infrastructure or credentials are used.
* Secrets, SSH keys, and generated VM images are excluded from Git.
* Destructive operations must validate team ownership.
* Shared infrastructure must remain unaffected.

Next Steps

* Implement Terraform and Ansible provisioning automation.
* Integrate WireGuard, Nomad, PostgreSQL, and S3-compatible storage.
* Develop the team-up and team-down Make targets.
* Validate idempotency, access isolation, and failure recovery.
* Perform complete provisioning and teardown tests.

Documentation

Detailed provisioning procedures and validation evidence:

Manual Provisioning Guide

Project Status

Local infrastructure validation completed.

Successfully provisioned an Ubuntu virtual machine, configured SSH authentication, and verified Ansible connectivity. The next phase focuses on automating the complete sandbox lifecycle, including secure resource provisioning and teardown.

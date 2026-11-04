# Intern Sandbox — Manual Provisioning Runbook

## Purpose

Document the manual steps required to provision and remove an isolated intern team sandbox before automating the lifecycle with Terraform, Ansible, and Make.

## Environment

- Team: lab-team-03
- Host: Ubuntu 22.04.5 on WSL2
- Virtualization: QEMU/KVM
- Guest OS: Ubuntu 22.04.5 LTS
- SSH: Ed25519 key authentication
- SSH forwarding: 127.0.0.1:2222 to guest port 22
- Automation: Terraform and Ansible

## Provisioning Checklist

1. Network: Create isolated networking and verify connectivity.
2. VM: Create a team-specific virtual disk from the Ubuntu cloud image.
3. Cloud-init: Configure hostname, user, and SSH key.
4. WireGuard: Create and register a team VPN peer.
5. Nomad: Create a team namespace and scoped ACL policy/token.
6. PostgreSQL: Create a team database and restricted database role.
7. S3: Create a team-specific storage bucket and scoped access credentials.
8. Validation: Verify resources and access permissions.

## Verified Lab Progress

- Ubuntu cloud image downloaded and validated.
- Cloud-init seed image created.
- Team VM disk created using a QCOW2 backing image.
- Ubuntu VM booted successfully.
- SSH public-key authentication succeeded.
- Ansible connectivity test succeeded.

## Teardown Checklist

1. Remove team workloads and Nomad ACL resources.
2. Revoke the WireGuard peer.
3. Terminate team database sessions and remove the database and role.
4. Remove team bucket contents and bucket.
5. Stop and delete the team VM and its disk.
6. Remove team-specific network resources.
7. Run an independent leftover-resource check.

## Safety Requirements

- All operations remain within the local lab.
- No production servers or credentials are used.
- Destructive operations must validate team ownership.
- Shared infrastructure must not be removed.
- Secrets and generated VM images must not be committed to Git.

## Outstanding Work

The WireGuard, Nomad, PostgreSQL, S3, and full network provisioning procedures still require implementation and validation.

The complete manual workflow will be updated as each component is tested.

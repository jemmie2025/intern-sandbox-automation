Sandbox Network Architecture and Connectivity

Overview

This document records the network configuration and connectivity validation for the lab-team-03 Ubuntu virtual machine in the Intern Sandbox Automation project.

Environment

* Host: Windows 11 with WSL2 Ubuntu
* Virtualization: QEMU/KVM
* Guest operating system: Ubuntu 22.04
* Virtual machine hostname: lab-team-03
* Network mode: QEMU user-mode networking (NAT)

Verified Network Configuration

Parameter	Value
Hostname	lab-team-03
Network interface	enp0s2
IPv4 address	10.0.2.15/24
Default gateway	10.0.2.2
SSH forwarding	Host port 2222 to guest port 22
Interface state	UP

The guest receives its network configuration through DHCP.

Connectivity Validation

The following checks were completed successfully:

1. SSH access to the guest through the configured localhost port forwarding.
2. Verification of the guest hostname, IPv4 address, and routing table.
3. Outbound ICMP connectivity to 1.1.1.1.

4. DNS resolution using `getent ahostsv4 example.com`.

### DNS Validation

- Command: `getent ahostsv4 example.com`
- Result: Successfully resolved the domain to IPv4 addresses.
- Observed addresses: `172.66.147.243`, `104.20.23.154`
- Status: Passed
### ICMP Test Results

* Packets transmitted: 3
* Packets received: 3
* Packet loss: 0%
* Average round-trip time: 8.346 ms

These results confirm basic outbound IP connectivity during testing.

Security and Isolation Considerations

QEMU user-mode networking provides NAT-based guest connectivity. The current configuration is suitable for local development and initial validation but does not establish verified isolation between multiple team environments.

Team-specific network isolation, WireGuard peer configuration, and access-control enforcement remain pending.

## Next Steps

1. Document and implement WireGuard peer provisioning.
2. Define team-specific network and access-control requirements.
3. Integrate network provisioning into the automated sandbox lifecycle.
4. Validate connectivity and isolation during provisioning and teardown.

Validation Status

**Status:** SSH connectivity, IPv4 configuration, default routing, outbound IP connectivity, and DNS resolution successfully verified.

**Outstanding:** WireGuard provisioning, multi-team network isolation, and automated lifecycle testing.

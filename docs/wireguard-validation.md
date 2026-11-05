# WireGuard VPN — Lab Validation

## Overview

Implemented and validated a WireGuard VPN between the WSL2 development host and the Ubuntu QEMU/KVM sandbox VM `lab-team-03`.

## Configuration

| Component | Configuration |
|---|---|
| Host | WSL2 Ubuntu |
| Peer | Ubuntu 22.04 VM |
| Interface | wg-lab |
| Host tunnel IP | 10.77.3.1 |
| VM tunnel IP | 10.77.3.2 |
| Host UDP port | 51820 |
| VM UDP port | 51821 |
| Peer endpoint | 10.0.2.2:51820 |
| Keepalive | 25 seconds |

## Validation Results

- WireGuard tools installed on both endpoints.
- Kernel interface creation verified.
- Separate WireGuard key pairs generated.
- Private key permissions restricted to 600.
- Authenticated WireGuard handshake established.
- Encrypted tunnel connectivity verified using ICMP.
- Three packets transmitted and received.
- Packet loss: 0%.
- Average round-trip latency: 3.412 ms.

## Security

Private keys and generated configurations remain outside Git tracking.

The local `lab/wireguard/` directory is excluded through `.gitignore`.

No production infrastructure or credentials were used.

## Outstanding Work

- Automate WireGuard peer provisioning.
- Implement peer revocation and teardown.
- Validate multi-team network isolation.
- Add reproducible configuration and integration tests.

## Status

Manual WireGuard VPN proof of concept successfully validated.

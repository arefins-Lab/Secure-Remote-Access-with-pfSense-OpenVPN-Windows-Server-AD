Secure Remote Access with pfSense OpenVPN & Windows Server AD
A complete remote access environment built with pfSense OpenVPN and Windows Server Active Directory.
This project demonstrates secure VPN connectivity, identity‑based authentication, and a fully functional internal network with DNS, DHCP, and domain services.

## Project Overview
Secure OpenVPN‑based remote access
Centralized identity authentication using Windows Server AD
Fully configured DNS & DHCP infrastructure
pfSense as the security and routing gateway
Clean separation of WAN, VPN, and LAN networks
Remote clients accessing internal resources through encrypted tunnels

## Key Features
Encrypted VPN Tunnel (10.10.10.0/24) for remote clients
Active Directory Domain Services for authentication
DNS with forwarders, scavenging, and validation
DHCP with reservations, options, and failover
pfSense Firewall Rules for WAN, OpenVPN, and LAN
NAT & Routing configured for seamless access to internal hosts
Internal LAN (192.168.1.0/24) with DC, ADC, and client systems

## Architecture Diagrams
All diagrams are included in the project and illustrate:
Full network topology
OpenVPN connection flow
Firewall rule logic
These visuals provide a clear understanding of how traffic flows from remote clients to pfSense and then to internal servers.

## What This Project Demonstrates
Designing a secure remote access solution
Implementing VPN authentication with AD
Building a production‑style Windows Server environment
Creating a pfSense‑based security gateway
Documenting infrastructure in a clean, professional format

## Status
This project is complete and has been validated end-to-end.

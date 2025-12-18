#!/bin/sh
#
# pfSense OpenVPN Remote Access Setup - Reference Script
# This script DOES NOT directly modify pfSense.
# It prints a step-by-step, error-proof sequence
# you can follow from the pfSense Web GUI / Shell.
#

echo "============================================================"
echo "  pfSense OpenVPN Remote Access - Configuration Sequence"
echo "============================================================"
echo
echo "Assumptions:"
echo "  - pfSense already installed"
echo "  - WAN/LAN configured"
echo "  - Time/NTP and DNS are working"
echo "  - Internal network: 192.168.1.0/24"
echo "  - Tunnel network:   10.10.10.0/24"
echo "  - Internal DNS:     192.168.1.10 (Domain Controller)"
echo

echo "------------------------------------------------------------"
echo "STEP 1: Create Certificate Authority (CA)"
echo "------------------------------------------------------------"
cat << 'EOF'

Web GUI:
  1) System -> Cert. Manager -> CAs -> Add
  2) Descriptive name: MyLab-CA
  3) Method: Create internal Certificate Authority
  4) Key length: 4096
  5) Digest Algorithm: SHA256
  6) Fill in Country/Org if needed
  7) Save

EOF

echo "------------------------------------------------------------"
echo "STEP 2: Create OpenVPN Server Certificate"
echo "------------------------------------------------------------"
cat << 'EOF'

Web GUI:
  1) System -> Cert. Manager -> Certificates -> Add
  2) Method: Create an internal certificate
  3) Descriptive name: OpenVPN-Server
  4) Certificate authority: MyLab-CA
  5) Certificate Type: Server Certificate
  6) Common Name: OpenVPN-Server
  7) Save

EOF

echo "------------------------------------------------------------"
echo "STEP 3: Create OpenVPN Server (Remote Access)"
echo "------------------------------------------------------------"
cat << 'EOF'

Web GUI:
  1) VPN -> OpenVPN -> Servers -> Add

  General:
    - Server mode: Remote Access (User Auth)
    - Backend for authentication: Local Database
    - Protocol: UDP
    - Device mode: tun
    - Interface: WAN
    - Local port: 1194

  Cryptographic settings:
    - TLS key: Auto-generate
    - Peer Certificate Authority: MyLab-CA
    - Server certificate: OpenVPN-Server
    - DH parameters length: 2048 bits
    - TLS Authentication: Enabled
    - Auth digest algorithm: SHA256
    - Encryption algorithm: AES-256-GCM (or AES-256-CBC if needed)

  Tunnel settings:
    - Tunnel network: 10.10.10.0/24
    - Local network(s): 192.168.1.0/24
    - Redirect gateway: (optional) Enable if you want full-tunnel

  Client settings:
    - Dynamic IP: Enable
    - Address Pool: Enable
    - Topology: Subnet

  DNS settings (Advanced client settings):
    - DNS server 1: 192.168.1.10   (Internal DNS / Domain Controller)
    - DNS domain:  mylab.test

  Save and Apply.

EOF

echo "------------------------------------------------------------"
echo "STEP 4: Create Firewall Rules for OpenVPN"
echo "------------------------------------------------------------"
cat << 'EOF'

Web GUI:
  1) Firewall -> Rules -> WAN
     - Confirm pfSense auto-created rule:
       * Action: Pass
       * Protocol: UDP
       * Destination port: 1194
       * Destination: This firewall (WAN address)

  2) Firewall -> Rules -> OpenVPN -> Add
     - Action: Pass
     - Interface: OpenVPN
     - Protocol: Any
     - Source: OpenVPN net
     - Destination: LAN net
     - Description: Allow VPN clients to access LAN
     - Save, then Apply changes

Optional (more open in lab):
  - Destination: Any

EOF

echo "------------------------------------------------------------"
echo "STEP 5: Create VPN User and Certificate"
echo "------------------------------------------------------------"
cat << 'EOF'

Web GUI:
  1) System -> User Manager -> Add
     - Username: vpnuser (or any)
     - Password: strong password
     - Full name: (optional)
     - Click: Create certificate
        * Certificate authority: MyLab-CA
        * Certificate type: User Certificate
     - Save

EOF

echo "------------------------------------------------------------"
echo "STEP 6: Export OpenVPN Client Configuration"
echo "------------------------------------------------------------"
cat << 'EOF'

Web GUI:
  1) System -> Package Manager -> Available Packages
     - Install: openvpn-client-export

  2) After install:
     - VPN -> OpenVPN -> Client Export

  3) In the Export tab:
     - Remote Access Server: select your OpenVPN server
     - Find user: vpnuser
     - Export for Windows:
       * e.g. Windows Installer or Viscosity / generic .ovpn

  4) Copy installer / .ovpn file to client device

EOF

echo "------------------------------------------------------------"
echo "STEP 7: Client-side Setup (Windows example)"
echo "------------------------------------------------------------"
cat << 'EOF'

On Windows client:
  1) Install OpenVPN (or run the exported installer).
  2) Import the .ovpn profile if needed.
  3) Connect using the vpnuser credentials.
  4) Verify:
     - You receive a 10.10.10.x IP address.
     - You can ping pfSense LAN IP (e.g. 192.168.1.1).
     - You can ping the Domain Controller (192.168.1.10).
     - DNS works:
         nslookup DC-SRV01.mylab.test
     - RDP works:
         mstsc -> 192.168.1.10 or DC-SRV01.mylab.test

EOF

echo "------------------------------------------------------------"
echo "STEP 8: Validation Checklist (Quick)"
echo "------------------------------------------------------------"
cat << 'EOF'

From VPN client:
  - Check IP: you have a 10.10.10.x address
  - Ping 192.168.1.1 (pfSense LAN)
  - Ping 192.168.1.10 (Domain Controller)
  - nslookup DC-SRV01.mylab.test (DNS via VPN)
  - RDP to DC and ADC

If all pass, OpenVPN on pfSense is working end-to-end.

EOF

echo "============================================================"
echo " pfSense OpenVPN configuration sequence printed successfully."
echo " Save this file in your GitHub Scripts/ folder for reference."
echo "============================================================"

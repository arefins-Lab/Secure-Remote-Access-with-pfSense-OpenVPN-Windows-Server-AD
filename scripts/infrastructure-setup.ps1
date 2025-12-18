<# 
===========================================================
  WINDOWS SERVER AUTOMATION SCRIPT
  DC + DNS + DHCP + ADC (All-in-One)
===========================================================
#>

# ================================
# VARIABLES (EDIT THESE ONLY)
# ================================
$DomainName          = "mylab.test"
$DomainNetbios       = "MYLAB"
$SafeModePassword    = (ConvertTo-SecureString "P@ssw0rd!" -AsPlainText -Force)

$DCIPAddress         = "192.168.1.10"
$ADCIPAddress        = "192.168.1.11"
$PrefixLength        = 24
$DefaultGateway      = "192.168.1.1"

$ScopeName           = "LAN-Scope"
$ScopeStart          = "192.168.1.100"
$ScopeEnd            = "192.168.1.200"
$ScopeSubnetMask     = "255.255.255.0"
$ScopeRouter         = "192.168.1.1"
$ScopeDNSServer      = "192.168.1.10"
$ScopeDNSDomain      = "mylab.test"

# ================================
# DETECT SERVER ROLE
# ================================
$hostname = $env:COMPUTERNAME

Write-Host "Running unified infrastructure setup on: $hostname" -ForegroundColor Cyan

# ================================
# PART 1 — PRIMARY DC SETUP
# ================================
if ($hostname -eq "DC-SRV01") {

    Write-Host "Configuring PRIMARY DOMAIN CONTROLLER..." -ForegroundColor Yellow

    # ---- Set Static IP ----
    $nic = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1

    New-NetIPAddress `
        -InterfaceIndex $nic.IfIndex `
        -IPAddress $DCIPAddress `
        -PrefixLength $PrefixLength `
        -DefaultGateway $DefaultGateway

    Set-DnsClientServerAddress `
        -InterfaceIndex $nic.IfIndex `
        -ServerAddresses $DCIPAddress

    # ---- Install Roles ----
    Install-WindowsFeature AD-Domain-Services, DNS, DHCP -IncludeManagementTools

    # ---- Promote to DC ----
    Install-ADDSForest `
        -DomainName $DomainName `
        -DomainNetbiosName $DomainNetbios `
        -SafeModeAdministratorPassword $SafeModePassword `
        -InstallDNS:$true `
        -Force:$true

    # Server will reboot automatically
}

# ================================
# PART 2 — POST-DC CONFIG (DNS + DHCP)
# ================================
if ($hostname -eq "DC-SRV01" -and (Get-ADDomain -ErrorAction SilentlyContinue)) {

    Write-Host "Running post-DC configuration..." -ForegroundColor Yellow

    # ---- Create Reverse Lookup Zone ----
    Add-DnsServerPrimaryZone `
        -NetworkId "192.168.1.0/24" `
        -ReplicationScope "Forest" `
        -DynamicUpdate "Secure"

    # ---- DHCP Authorization ----
    Add-DhcpServerInDC -DnsName "$hostname.$DomainName" -IpAddress $DCIPAddress

    # ---- Create DHCP Scope ----
    Add-DhcpServerv4Scope `
        -Name $ScopeName `
        -StartRange $ScopeStart `
        -EndRange $ScopeEnd `
        -SubnetMask $ScopeSubnetMask `
        -State Active

    # ---- DHCP Options ----
    Set-DhcpServerv4OptionValue `
        -ScopeId "192.168.1.0" `
        -Router $ScopeRouter `
        -DnsServer $ScopeDNSServer `
        -DnsDomain $ScopeDNSDomain

    Start-Service DHCPServer
}

# ================================
# PART 3 — ADC SETUP
# ================================
if ($hostname -eq "ADC-SRV01") {

    Write-Host "Configuring ADDITIONAL DOMAIN CONTROLLER..." -ForegroundColor Yellow

    # ---- Set Static IP ----
    $nic = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1

    New-NetIPAddress `
        -InterfaceIndex $nic.IfIndex `
        -IPAddress $ADCIPAddress `
        -PrefixLength $PrefixLength `
        -DefaultGateway $DefaultGateway

    Set-DnsClientServerAddress `
        -InterfaceIndex $nic.IfIndex `
        -ServerAddresses $DCIPAddress

    # ---- Install AD DS ----
    Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

    # ---- Promote to ADC ----
    Install-ADDSDomainController `
        -DomainName $DomainName `
        -InstallDNS:$true `
        -SafeModeAdministratorPassword $SafeModePassword `
        -Force:$true

    # Server will reboot automatically
}

# ================================
# PART 4 — ADC POST-REBOOT CHECK
# ================================
if ($hostname -eq "ADC-SRV01" -and (Get-ADDomain -ErrorAction SilentlyContinue)) {

    Write-Host "Running ADC validation..." -ForegroundColor Yellow

    Get-ADDomainController -Filter *
    repadmin /replsummary
    Get-DnsServerZone

    Write-Host "ADC configuration completed successfully." -ForegroundColor Green
}

Write-Host "Unified infrastructure script completed." -ForegroundColor Green

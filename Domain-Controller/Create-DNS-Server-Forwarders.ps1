<#
.SYNOPSIS
    Configure DNS forwarders on this server.

.DESCRIPTION
    - Imports the DNS Server PowerShell module.
    - Defines an array of external DNS IPs to forward unresolved queries to.
    - Adds each forwarder only if it’s not already configured.
    - Ensures recursion is enabled so that forwarding can occur.

.NOTES
    * Must be run elevated (as Administrator).
    * Tested on Windows Server 2012 R2 / 2016 / 2019 / 2022.
#>

# -------------------------------
# 1) Import the DNS Server module
#    Provides Add-DnsServerForwarder, Get-DnsServerForwarder, etc.
# -------------------------------
Import-Module DnsServer -ErrorAction Stop

# -------------------------------
# 2) Define your forwarder IP addresses
#    Change these to your preferred public or ISP DNS servers.
# -------------------------------
$ForwarderIPs = @(
    '8.8.8.8',   # Google Public DNS
    '1.1.1.1'    # Cloudflare DNS
)

# -------------------------------
# 3) Loop through each IP and add it if missing
# -------------------------------
foreach ($ip in $ForwarderIPs) {
    # Check if this IP is already a configured forwarder
    $exists = Get-DnsServerForwarder -IPAddress $ip -ErrorAction SilentlyContinue

    if (-not $exists) {
        # Add the forwarder
        Add-DnsServerForwarder -IPAddress $ip -PassThru |
            Write-Host "✅ Added DNS forwarder: $ip"
    }
    else {
        Write-Host "ℹ️  Forwarder $ip already exists, skipping."
    }
}

# -------------------------------
# 4) (Optional) Ensure recursion is enabled globally
#    Forwarding only works if recursion isn’t disabled.
# -------------------------------
try {
    # Use WMI to flip the DisableRecursion flag to $false (0)
    $dns = Get-WmiObject -Namespace 'root\MicrosoftDNS' -Class 'MicrosoftDNS_Server'
    if ($dns.DisableRecursion -ne 0) {
        $dns.DisableRecursion = 0
        $dns.Put() | Out-Null
        Write-Host "✅ Recursion enabled on DNS server."
    }
    else {
        Write-Host "ℹ️  Recursion is already enabled."
    }
}
catch {
    Write-Warning "Unable to verify/modify recursion setting: $_"
}

# -------------------------------
# 5) Done
# -------------------------------
Write-Host "All done – forwarders configured and recursion checked." 

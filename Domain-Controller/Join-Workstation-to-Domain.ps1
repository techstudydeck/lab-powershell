<#
.SYNOPSIS
    Join this Windows 10 machine to the lab.local domain.

.DESCRIPTION
    1. Verifies script is running as Administrator.
    2. Prompts for domain credentials (e.g. lab\Administrator or user@lab.local).
    3. Joins machine to lab.local (default Computers container).
    4. Forces a reboot on success.

.NOTES
    * Tested on Windows 10 / Server 2022 AD domains.
    * Save as Join-LabDomain.ps1 and run in an elevated session.
#>

# 1) Ensure we're running as Administrator
$current = [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $current.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script must be run as Administrator."
    exit 1
}

# 2) Define your domain and (optional) OU path
$DomainName = 'lab.local'
# If you have a specific OU, uncomment and adjust:
# $OUPath = 'OU=Workstations,OU=Lab,DC=lab,DC=local'
$OUPath = $null

# 3) Prompt for domain-join credentials
$Cred = Get-Credential -Message "Enter credentials for joining $DomainName"

# 4) Attempt to join
Write-Host "Joining domain $DomainName…" -ForegroundColor Cyan
try {
    if ($OUPath) {
        Add-Computer -DomainName $DomainName -Credential $Cred -OUPath $OUPath -Force
    } else {
        Add-Computer -DomainName $DomainName -Credential $Cred -Force
    }
}
catch {
    Write-Error "Domain join failed: $_"
    exit 2
}

# 5) On success, reboot
Write-Host "✅ Successfully joined $DomainName. Rebooting now…" -ForegroundColor Green
Restart-Computer -Force

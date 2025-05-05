# Install AD DS Role & Promote to a New Forest

# Parameters – adjust to taste
$DomainName = "lab.local"
$SafeModePwd = Read-Host "Enter DSRM (SafeMode) password" -AsSecureString

# 1. Install AD Domain Services (and DNS)
Write-Host "Installing AD DS role + DNS..." -ForegroundColor Cyan
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools |
    Format-Table -AutoSize

# 2. Import the Deployment module
Import-Module ADDSDeployment

# 3. Promote this server to be a new forest root
Write-Host "Promoting $env:COMPUTERNAME to a new forest: $DomainName" -ForegroundColor Cyan
Install-ADDSForest `
  -DomainName $DomainName `
  -CreateDnsDelegation:$false `
  -DatabasePath "C:\Windows\NTDS" `
  -DomainMode "WinThreshold" `
  -ForestMode "WinThreshold" `
  -LogPath "C:\Windows\NTDS" `
  -SysvolPath "C:\Windows\SYSVOL" `
  -SafeModeAdministratorPassword $SafeModePwd `
  -NoRebootOnCompletion:$false `
  -Force

# (The server will automatically reboot once promotion finishes.)


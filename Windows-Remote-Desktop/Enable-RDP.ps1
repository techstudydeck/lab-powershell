# 1. Allow Remote Desktop connections
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' `
                 -Name 'fDenyTSConnections' -Value 0

# 2. (Optional but recommended) Require Network Level Authentication
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' `
                 -Name 'UserAuthentication' -Value 1

# 3. Open the firewall for RDP
Enable-NetFirewallRule -DisplayGroup 'Remote Desktop'

# 4. Ensure the Remote Desktop Service is automatic and running
Set-Service -Name TermService -StartupType Automatic
Start-Service -Name TermService

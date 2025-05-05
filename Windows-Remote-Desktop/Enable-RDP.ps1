# 1. Allow Remote Desktop connections
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' `
                 -Name 'fDenyTSConnections' -Value 0

# 2. (Optional but recommended) Require Network Level Authentication
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' `
                 -Name 'UserAuthentication' -Value 1

# 3. Allow inbound RDP (TCP 3389) on Domain, Private & Public profiles (Lab purposes only, not for production)
New-NetFirewallRule `
  -Name "Allow-RDP-Inbound" `
  -DisplayName "Allow RDP (TCP 3389)" `
  -Protocol TCP `
  -LocalPort 3389 `
  -Direction Inbound `
  -Action Allow `
  -Profile Any

# 4. Ensure the Remote Desktop Service is automatic and running
Set-Service -Name TermService -StartupType Automatic
Start-Service -Name TermService

# 5. Allow inbound ICMPv4 Echo Request (ping) on all profiles
New-NetFirewallRule `
  -Name "Allow-Ping-Inbound" `
  -DisplayName "Allow Ping (ICMPv4 Echo Request)" `
  -Protocol ICMPv4 `
  -IcmpType 8 `
  -Direction Inbound `
  -Action Allow `
  -Profile Any

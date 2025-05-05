# Rename the Computer and Reboot
# Desired new name for this DC - Running this script will reboot the endpoint. You would want to name your domain controller something meaningful.
$NewName = "DC01"

# Get current computer name
$Current = $env:COMPUTERNAME

if ($Current -ieq $NewName) {
    Write-Host "Already named $NewName – skipping rename."
} else {
    Write-Host "Renaming computer from $Current to $NewName..."
    Rename-Computer -NewName $NewName -Force
    Write-Host "Rebooting now to apply new name..."
    Restart-Computer
}

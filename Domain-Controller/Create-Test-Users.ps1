<#
.SYNOPSIS
Creates OUs and example user accounts in Active Directory, generates random passwords, exports credentials to CSV.

.DESCRIPTION
This script:
1. Ensures the C:\Temp directory exists.
2. Defines Organizational Units (OUs) and example users.
3. Creates each OU under the current domain.
4. Generates a random password for each user.
5. Creates the user account in the corresponding OU.
6. Exports all username/passwords to C:\Temp\ad-user-credentials.csv for reference.
#>

# Import the Active Directory module; stops on error if not available
Import-Module ActiveDirectory -ErrorAction Stop

# Define export directory and file
$exportDir  = "C:\Temp"
$exportFile = "ad-user-credentials.csv"
$exportPath = Join-Path -Path $exportDir -ChildPath $exportFile

# 1) Ensure the export directory exists; if not, create it
if (-not (Test-Path -Path $exportDir)) {
    Write-Host "Creating directory $exportDir"
    New-Item -ItemType Directory -Path $exportDir | Out-Null
} else {
    Write-Host "Directory $exportDir already exists; proceeding..."
}

# 2) Get the current domain's distinguished name (DN)
$domainDN = (Get-ADDomain).DistinguishedName

# 3) Define OUs and user lists
$structure = @{
    "Staff"            = @("jdoe","asmith")
    "Contractors"     = @("contractor1","contractor2")
    "Service Accounts"= @("svc-automation","svc-backup")
}

# Function to generate a secure random password using .NET's Membership class
function New-RandomPassword {
    param(
        [int]$Length               = 14,
        [int]$NonAlphanumericCount = 3
    )
    return [System.Web.Security.Membership]::GeneratePassword($Length, $NonAlphanumericCount)
}

# 4) Prepare an array to collect credentials for export
$credentials = @()

# 5) Loop through each OU definition
foreach ($ouName in $structure.Keys) {
    # Construct the OU path DN
    $ouDN = "OU=$ouName,$domainDN"

    # Check if OU exists; create it if missing
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$ouName'" -ErrorAction SilentlyContinue)) {
        Write-Host "Creating OU: $ouName"
        New-ADOrganizationalUnit -Name $ouName -Path $domainDN -ProtectedFromAccidentalDeletion:$false
    } else {
        Write-Host "OU '$ouName' already exists; skipping creation."
    }

    # Create each user in the OU
    foreach ($sam in $structure[$ouName]) {
        # Generate passwords
        $plainPwd  = New-RandomPassword -Length 14 -NonAlphanumericCount 3
        $securePwd = ConvertTo-SecureString $plainPwd -AsPlainText -Force

        Write-Host "Creating user $sam in OU $ouName"
        New-ADUser `
            -Name               $sam `
            -SamAccountName     $sam `
            -AccountPassword    $securePwd `
            -Enabled            $true `
            -Path               $ouDN `
            -ChangePasswordAtLogon:$false

        # Collect info for CSV export
        $credentials += [PSCustomObject]@{
            SamAccountName = $sam
            Password       = $plainPwd
            OU             = $ouName
        }
    }
}

# 6) Export all credentials to CSV for record keeping
Write-Host "Exporting credentials to $exportPath"
$credentials | Export-Csv -Path $exportPath -NoTypeInformation

Write-Host "Done. Review the CSV at $exportPath for the new account credentials."

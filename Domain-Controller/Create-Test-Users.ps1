<#
.SYNOPSIS
Creates OUs and example user accounts in Active Directory, generates secure random passwords, and exports credentials to a CSV.

.DESCRIPTION
This script performs the following steps:
1. Ensures the C:\Temp directory exists.
2. Defines Organizational Units (OUs) and associated example users.
3. Creates each OU under the current Active Directory domain if it doesn't already exist.
4. Generates secure random passwords meeting common AD complexity requirements.
5. Creates the user account in the corresponding OU with the generated password and a default UPN.
6. Exports all usernames, passwords, and user details to C:\Temp\ad-user-credentials.csv.

.NOTES
- Detailed comments provided for clarity and public GitHub use.
- Requires ActiveDirectory PowerShell module.
#>

# Import the Active Directory module; stop if not available
Import-Module ActiveDirectory -ErrorAction Stop

# Define export directory and file
$exportDir  = 'C:\Temp'
$exportFile = 'ad-user-credentials.csv'
$exportPath = Join-Path -Path $exportDir -ChildPath $exportFile

# Step 1: Ensure the export directory exists
if (-not (Test-Path -Path $exportDir)) {
    Write-Host "Creating directory $exportDir"
    New-Item -ItemType Directory -Path $exportDir | Out-Null
} else {
    Write-Host "Directory $exportDir already exists."
}

# Step 2: Retrieve the current domain's distinguished name and DNS root
$domain = Get-ADDomain
$domainDN = $domain.DistinguishedName
$domainSuffix = $domain.DNSRoot

# Step 3: Define OUs and their example users
$structure = @{
    'Staff' = @(
        @{ Sam='jdoe'; First='John'; Last='Doe' },
        @{ Sam='asmith'; First='Alice'; Last='Smith' }
    )
    'Contractors' = @(
        @{ Sam='contractor1'; First='Chris'; Last='Rogers' },
        @{ Sam='contractor2'; First='Jamie'; Last='Blake' }
    )
    'Service Accounts' = @(
        @{ Sam='svc-automation'; First='Svc'; Last='Automation' },
        @{ Sam='svc-backup'; First='Svc'; Last='Backup' }
    )
}

function New-RandomPassword {
    param([int]$Length = 14)
    if ($Length -lt 8) { throw "Password length must be at least 8 characters." }
    $upper   = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    $lower   = 'abcdefghijklmnopqrstuvwxyz'
    $digits  = '0123456789'
    $special = '!@#$%^&*()_-+=[]{}|;:,.<>?'
    $rng    = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $buffer = New-Object 'Byte[]' 4
    function Get-RandomChar($chars) {
        $rng.GetBytes($buffer)
        $idx = [System.BitConverter]::ToUInt32($buffer, 0) % $chars.Length
        return $chars[$idx]
    }
    $passwordChars = @(
        Get-RandomChar $upper
        Get-RandomChar $lower
        Get-RandomChar $digits
        Get-RandomChar $special
    )
    $allChars = $upper + $lower + $digits + $special
    for ($i = 0; $i -lt ($Length - 4); $i++) {
        $passwordChars += Get-RandomChar $allChars
    }
    return (-join ($passwordChars | Get-Random -Count $passwordChars.Length))
}

# Prepare an array to hold credential objects for export
$credentials = @()

# Step 4: Create OUs and users
foreach ($ouName in $structure.Keys) {
    $ouDN = "OU=$ouName,$domainDN"
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$ouName'" -ErrorAction SilentlyContinue)) {
        Write-Host "Creating OU: $ouName"
        New-ADOrganizationalUnit -Name $ouName -Path $domainDN -ProtectedFromAccidentalDeletion:$false
    } else {
        Write-Host "OU '$ouName' already exists."
    }
    foreach ($user in $structure[$ouName]) {
        $sam = $user.Sam
        $first = $user.First
        $last = $user.Last
        $plainPwd  = New-RandomPassword -Length 14
        $securePwd = ConvertTo-SecureString $plainPwd -AsPlainText -Force
        $upn = "$sam@$domainSuffix"
        $fullName = "$first $last"
        $address = "1234 Main St"
        $city = "Anytown"
        $state = "NY"
        $zip = "10001"
        $phone = "555-0101"

        Write-Host "Creating user $sam in OU $ouName with UPN $upn"
        New-ADUser `
            -Name $fullName `
            -GivenName $first `
            -Surname $last `
            -SamAccountName $sam `
            -UserPrincipalName $upn `
            -AccountPassword $securePwd `
            -Enabled $true `
            -Path $ouDN `
            -ChangePasswordAtLogon $false `
            -StreetAddress $address `
            -City $city `
            -State $state `
            -PostalCode $zip `
            -OfficePhone $phone

        $credentials += [PSCustomObject]@{
            SamAccountName = $sam
            UserPrincipalName = $upn
            FirstName = $first
            LastName = $last
            Password = $plainPwd
            Address = "$address, $city, $state $zip"
            Phone = $phone
            OU = $ouName
        }
    }
}

# Step 5: Export credentials to CSV
Write-Host "Exporting credentials to $exportPath"
$credentials | Export-Csv -Path $exportPath -NoTypeInformation

Write-Host "Done. Review the CSV at $exportPath for new account credentials."

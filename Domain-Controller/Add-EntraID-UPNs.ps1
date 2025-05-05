# Replace this with your actual suffix
$upnSuffix = "whateveryourEntraIDSuffixIs.onmicrosoft.com"

Get-ADUser -Filter * -SearchBase "OU=Staff,DC=lab,DC=local" | ForEach-Object {
    $newUpn = $_.SamAccountName + "@" + $upnSuffix
    Set-ADUser $_ -UserPrincipalName $newUpn
}

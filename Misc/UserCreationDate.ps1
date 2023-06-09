Connect-AzureAD 

$PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent 

$usrs = Get-AzureADUser -All:$true 

$usrs | ForEach-Object{

    Write-Host �Getting created date for� $_.UserPrincipalName

    $_ | Add-Member -MemberType NoteProperty -Name �CreatedDateTime� `

    -Value (Get-AzureADUserExtension -ObjectId $_.ObjectId).Get_Item(�createdDateTime�)

} 

$usrs | Export-CSV �$PSScriptRoot\userslist.csv� 

Disconnect-AzureAD 
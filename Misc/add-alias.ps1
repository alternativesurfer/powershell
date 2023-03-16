$cred = Get-Credential -Message 'Please enter your Office 365 admin crendentials'
$O365 = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri 'https://outlook.office365.com/powershell-liveid/' -Credential $cred -Authentication Basic -AllowRedirection 
$importcmd = Import-PSSession $O365 -CommandName @('Get-Mailbox','Set-Mailbox') -AllowClobber

Get-Mailbox -ResultSize Unlimited -Filter { EmailAddresses -like '*@iconusinc.com' } | Select-Object Identity,EmailAddresses | ForEach-Object {
    $proxyaddresses = $_.EmailAddresses | Where-Object { $_ -like 'smtp:*@iconusinc.com' }
    foreach ($proxyaddress in $proxyaddresses) {
        $newaddress = ($proxyaddress -split ':')[1] -replace '@iconusinc.com','@iconbuildingsupplies.com'
        Set-Mailbox -Identity $_.Identity -EmailAddresses @{Add="smtp:$newaddress"}    
    }
}
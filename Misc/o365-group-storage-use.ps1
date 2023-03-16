$userName ="admin@bridgehh.com"
$o365Cred = Get-Credential -UserName $userName -Message "Enter Office 365 Admin Credentials"
 
$o365Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $o365Cred -Authentication Basic -AllowRedirection
Import-PSSession $o365Session
 
$spoAdminUrl ="https://sterlinghc-admin.sharepoint.com/"
Connect-SPOService -Url $spoAdminUrl -Credential $o365Cred
 
$O365Groups = Get-UnifiedGroup -ResultSize Unlimited
 
$CustomResult=@() 
 
ForEach ($O365Group in $O365Groups){ 
If($O365Group.SharePointSiteUrl -ne $null) 
{ 
   $O365GroupSite=Get-SPOSite -Identity $O365Group.SharePointSiteUrl 
   $CustomResult += [PSCustomObject] @{ 
     GroupName =  $O365Group.DisplayName
     SiteUrl = $O365GroupSite.Url 
     StorageUsed_inMB = $O365GroupSite.StorageUsageCurrent
     StorageQuota_inGB = $O365GroupSite.StorageQuota/1024
     WarningSize_inGB =  $O365GroupSite.StorageQuotaWarningLevel/1024
  }
}} 
  
$CustomResult | FT
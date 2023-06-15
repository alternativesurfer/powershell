##### Allow Unsigned
Set-ExecutionPolicy unrestricted

##### Install
Install-Module -Name ExchangeOnlineManagement
Install-Module -Name MSOnline
Install-Module -Name AzureAD
Install-Module -Name Microsoft.Online.SharePoint.PowerShell
Install-Module -Name SharePointPnPPowerShellOnline
Install-Module -Name MicrosoftTeams
Install-Module -Name PartnerCenter -AllowClobber -Scope AllUsers
Install-Module -Name Microsoft.Graph.Intune
Install-Module -Name IntuneBackupAndRestore
install-module RunAsUser

##### Import
Import-Module -Name ExchangeOnlineManagement
Import-Module -Name MSOnline
Import-Module -Name AzureAD
Import-Module -Name Microsoft.Online.SharePoint.PowerShell
Import-Module -Name SharePointPnPPowerShellOnline
Import-Module -Name MicrosoftTeams
Import-Module -Name PartnerCenter
Import-Module -Name Microsoft.Graph.Intune
Import-Module -Name IntuneBackupAndRestore
Import-Module -Name RunAsUser

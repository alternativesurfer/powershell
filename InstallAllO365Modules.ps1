##### Allow Unsigned
Set-ExecutionPolicy unrestricted

##### Install
Install-Module -Name ExchangeOnlineManagement -Scope AllUsers -Force
Install-Module -Name MSOnline -Scope AllUsers -Force
Install-Module -Name AzureAD -Scope AllUsers -Force
Install-Module -Name Microsoft.Online.SharePoint.PowerShell -Scope AllUsers -Force
Install-Module -Name SharePointPnPPowerShellOnline -Scope AllUsers -Force
Install-Module -Name MicrosoftTeams -Scope AllUsers -Force
Install-Module -Name PartnerCenter -AllowClobber -Scope AllUsers -Force
Install-Module -Name Microsoft.Graph.Intune -Scope AllUsers -Force
Install-Module -Name IntuneBackupAndRestore -Scope AllUsers -Force
install-module RunAsUser -Scope AllUsers -Force
Install-Module Microsoft.Graph -Scope AllUsers -Force
Install-Module Microsoft.Graph.Beta -Scope AllUsers -Force
Install-Module -Name MSCommerce -Scope AllUsers -Force
Install-Module -Name AIPService -Scope AllUsers -Force

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
import-module -Name Microsoft.Graph
Import-Module -Name MSCommerce
Import-Module -Name AIPService

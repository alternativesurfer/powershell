#Settings
[PSCustomObject]@{
    PrefSched               = '7' #Options are: 0(Low Diskspace),1,7,30
    ClearTemporaryFiles     = $true
    ClearRecycler           = $true
    ClearDownloads          = $true
    AllowClearOneDriveCache = $true
    AddAllOneDrivelocations = $true
    ClearRecyclerDays       = '14' #Options are: 0(never),1,14,30,60
    ClearDownloadsDays      = '14' #Options are: 0(never),1,14,30,60
    ClearOneDriveCacheDays  = '14' #Options are: 0(never),1,14,30,60

} | ConvertTo-Json | Out-File "C:\Support\WantedStorageSenseSettings.txt"

#

If (Get-Module -ListAvailable -Name "RunAsUser") {
Import-module RunAsUser
}
Else {
Install-PackageProvider NuGet -Force
Set-PSRepository PSGallery -InstallationPolicy Trusted
Install-Module RunAsUser -force -Repository PSGallery
}

$ScriptBlock = {
    $WantedSettings = Get-Content "C:\Support\WantedStorageSenseSettings.txt" | ConvertFrom-Json
    $StorageSenseKeys = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy\'
    Set-ItemProperty -Path $StorageSenseKeys -name '01' -value '1' -Type DWord  -Force
    Set-ItemProperty -Path $StorageSenseKeys -name '04' -value $WantedSettings.ClearTemporaryFiles -Type DWord -Force
    Set-ItemProperty -Path $StorageSenseKeys -name '08' -value $WantedSettings.ClearRecycler -Type DWord -Force
    Set-ItemProperty -Path $StorageSenseKeys -name '32' -value $WantedSettings.ClearDownloads -Type DWord -Force
    Set-ItemProperty -Path $StorageSenseKeys -name '256' -value $WantedSettings.ClearRecyclerDays -Type DWord -Force
    Set-ItemProperty -Path $StorageSenseKeys -name '512' -value $WantedSettings.ClearDownloadsDays -Type DWord -Force
    Set-ItemProperty -Path $StorageSenseKeys -name '2048' -value $WantedSettings.PrefSched -Type DWord -Force
    Set-ItemProperty -Path $StorageSenseKeys -name 'CloudfilePolicyConsent' -value $WantedSettings.AllowClearOneDriveCache -Type DWord -Force
    if ($WantedSettings.AddAllOneDrivelocations) {
$CurrentUserSID = ([System.Security.Principal.WindowsIdentity]::GetCurrent()).User.Value
        $CurrentSites = Get-ItemProperty 'HKCU:\SOFTWARE\Microsoft\OneDrive\Accounts\Business1\ScopeIdToMountPointPathCache' -ErrorAction SilentlyContinue | Select-Object -Property * -ExcludeProperty PSPath, PsParentPath, PSChildname, PSDrive, PsProvider
        foreach ($OneDriveSite in $CurrentSites.psobject.properties.name) {
            New-Item "$($StorageSenseKeys)/OneDrive!$($CurrentUserSID)!Business1|$($OneDriveSite)" -Force
            New-ItemProperty "$($StorageSenseKeys)/OneDrive!$($CurrentUserSID)!Business1|$($OneDriveSite)" -Name '02' -Value '1' -type DWORD -Force
            New-ItemProperty "$($StorageSenseKeys)/OneDrive!$($CurrentUserSID)!Business1|$($OneDriveSite)" -Name '128' -Value $WantedSettings.ClearOneDriveCacheDays -type DWORD -Force
}
}

}

$null = Invoke-AsCurrentUser -ScriptBlock $ScriptBlock -UseWindowsPowerShell -NonElevatedSession

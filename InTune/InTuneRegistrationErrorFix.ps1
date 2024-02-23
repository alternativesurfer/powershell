# $sids = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\EnterpriseResourceManager\Tracked' -name |where-object {$_.Length -gt 25}
$sids = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Enrollments' -name |where-object {$_.Length -gt 25}
Foreach ($sid in $sids){
$enrollmentpath = "HKLM:\SOFTWARE\Microsoft\Enrollments\$($sid)"
#$entresourcepath = "HKLM:\SOFTWARE\Microsoft\EnterpriseResourceManager\Tracked\$($sid)"
 
$value1 = Test-Path $enrollmentpath
If ($value1 -eq $true) {
 
write-host "$($sid) exists and will be removed"
 
Remove-Item -Path $enrollmentpath -Recurse -confirm:$false
#Remove-Item -Path $entresourcepath -Recurse -confirm:$false
 
}
Else {Write-Host "The value does not exist, skipping"}
 }

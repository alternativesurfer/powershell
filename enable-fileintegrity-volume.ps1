$volumePath = Read-Host "What is the name of the Domain you are checking?"

# Enable FileIntegrity for all files in the volume recursively
$files = Get-ChildItem -Path $volumePath -Recurse -File
foreach ($file in $files) {
    Set-FileIntegrity -Path $file.FullName -Enable $true
}
$folder2 = "D:\Google Photos\Takeout\Dupes"
$folder1 = "D:\Google Photos\Takeout\Google Photos"
$logFile = Join-Path $folder2 "!merge_log.txt"

# Clear previous log file if it exists
if (Test-Path $logFile) {
    Remove-Item $logFile
}

# Get all files from Folder1 recursively
Get-ChildItem -Path $folder1 -Recurse -File | ForEach-Object {
    $relativePath = $_.FullName.Substring($folder1.Length).TrimStart("\")
    $destinationPath = Join-Path $folder2 $relativePath

    # Ensure the destination directory exists
    $destinationDir = Split-Path $destinationPath
    if (!(Test-Path $destinationDir)) {
        New-Item -Path $destinationDir -ItemType Directory -Force | Out-Null
    }

    if (Test-Path $destinationPath) {
        # Compare file sizes
        $sourceSize = $_.Length
        $destinationSize = (Get-Item $destinationPath).Length

        if ($sourceSize -gt $destinationSize) {
            # Overwrite with larger file and log it
            Copy-Item $_.FullName -Destination $destinationPath -Force
            $logEntry = "Overwritten: $relativePath (source: $sourceSize bytes, dest: $destinationSize bytes)"
            Add-Content -Path $logFile -Value $logEntry
        }
    } else {
        # Copy new file
        Copy-Item $_.FullName -Destination $destinationPath -Force
    }
}
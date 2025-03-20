# Define the URL and download location
$DownloadURL = "https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-win64.zip"
$DownloadLocation = "C:\Support\SpeedtestCLI"
$ZipFilePath = Join-Path -Path $DownloadLocation -ChildPath "speedtest.zip"
$SpeedtestExePath = Join-Path -Path $DownloadLocation -ChildPath "speedtest.exe"
$ResultsFile = Join-Path -Path $DownloadLocation -ChildPath "results.csv"

# Create the download directory if it doesn't exist
if (-Not (Test-Path -Path $DownloadLocation)) {
    New-Item -Path $DownloadLocation -ItemType Directory -Force | Out-Null
}

# Download the ZIP file
Invoke-WebRequest -Uri $DownloadURL -OutFile $ZipFilePath

# Extract the ZIP file contents
Expand-Archive -Path $ZipFilePath -DestinationPath $DownloadLocation -Force

# Optional: Remove the ZIP file after extraction
Remove-Item -Path $ZipFilePath -Force

# Check if speedtest.exe exists before running
if (Test-Path -Path $SpeedtestExePath) {

    # Define the correct CSV header based on actual output fields
    $CSVHeader = "Server State,Server ID,Latency (ms),Jitter (ms),Packet Loss (%),Download (Mbps),Upload (Mbps),Download Bytes,Upload Bytes,Share URL,Timestamp"

    # Run speedtest-cli with license and GDPR acceptance, Mbps output, and CSV format
    $SpeedtestResult = & $SpeedtestExePath --accept-license --accept-gdpr --format=csv --unit=Mbps

    # If results.csv doesn't exist, create it and add the header first
    if (-Not (Test-Path -Path $ResultsFile)) {
        Add-Content -Path $ResultsFile -Value $CSVHeader
    }

    # Split the result into individual fields (comma-delimited)
    $ResultFields = $SpeedtestResult -split ","

    # Check if we have enough fields (should have 11)
    if ($ResultFields.Length -ge 11) {
        # Extract the relevant fields from the Speedtest result
        $ServerID = $ResultFields[1]    # Server ID
        $Latency = $ResultFields[2]     # Latency (ms)
        $Jitter = $ResultFields[3]      # Jitter (ms)
        $PacketLoss = $ResultFields[4]  # Packet Loss (%)
        
        # Trim the quotation marks around the values and convert to double
        $DownloadRaw = $ResultFields[5].Trim('"')  # Download value
        $UploadRaw = $ResultFields[6].Trim('"')    # Upload value
        
        # Print out the raw values for debugging
        Write-Host "Raw Download Value: $DownloadRaw"
        Write-Host "Raw Upload Value: $UploadRaw"
        
        # Attempt explicit conversion to double using [double] and ensuring valid data type
        try {
            $DownloadMbps = [double]$DownloadRaw  # Converting to double
        } catch {
            Write-Host "Error converting Download value: $_" -ForegroundColor Red
            $DownloadMbps = 0
        }

        try {
            $UploadMbps = [double]$UploadRaw    # Converting to double
        } catch {
            Write-Host "Error converting Upload value: $_" -ForegroundColor Red
            $UploadMbps = 0
        }

        # Check if conversion was successful and print the type of data
        Write-Host "Converted Download (Mbps): $DownloadMbps (Type: $($DownloadMbps.GetType()))"
        Write-Host "Converted Upload (Mbps): $UploadMbps (Type: $($UploadMbps.GetType()))"
        
        # Additional check for valid values before dividing
        if ($DownloadMbps -gt 0) {
            $DownloadMbps = [math]::round($DownloadMbps / 100000, 6)  # Divide by 100000 and round
        } else {
            Write-Host "Invalid Download value, skipping division." -ForegroundColor Red
        }

        if ($UploadMbps -gt 0) {
            $UploadMbps = [math]::round($UploadMbps / 100000, 6)  # Divide by 100000 and round
        } else {
            Write-Host "Invalid Upload value, skipping division." -ForegroundColor Red
        }

        # Continue extracting other values
        $DownloadBytes = $ResultFields[7]  # Download Bytes
        $UploadBytes = $ResultFields[8]    # Upload Bytes
        $ShareURL = $ResultFields[9]       # Share URL
        
        # Get the current timestamp for when the file is updated
        $Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"

        # Construct the truncated result with adjusted values (no Server Name)
        $TruncatedResult = "$ServerID,$Latency,$Jitter,$PacketLoss,$DownloadMbps,$UploadMbps,$DownloadBytes,$UploadBytes,$ShareURL,$Timestamp"

        # Append the truncated result to the CSV file
        Add-Content -Path $ResultsFile -Value $TruncatedResult

        Write-Host "Speedtest completed and results appended to $ResultsFile" -ForegroundColor Green
    } else {
        Write-Host "Error: Speedtest result is not in expected format" -ForegroundColor Red
    }
} else {
    Write-Host "Speedtest executable not found. Please check the extraction process." -ForegroundColor Red
}

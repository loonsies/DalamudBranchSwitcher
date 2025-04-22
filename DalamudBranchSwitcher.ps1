# Download and parse the YAML file
$yamlUrl = "https://raw.githubusercontent.com/goatcorp/dalamud-declarative/refs/heads/main/config.yaml"

try {
    Write-Host "Downloading YAML file..."
    $yamlContent = Invoke-WebRequest -Uri $yamlUrl -UseBasicParsing | Select-Object -ExpandProperty Content
    
    # Convert the YAML content to a PowerShell object
    $tracks = @{}
    $currentTrack = $null
    $inTracks = $false
    
    # Split content into lines and preserve original indentation
    $lines = $yamlContent -split "`n" | ForEach-Object { $_ -replace "`r", "" }
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        
        # Check if we're in the tracks section
        if ($line.Trim() -eq "tracks:") {
            $inTracks = $true
            continue
        }
        
        if ($inTracks) {
            # Parse track names (looking for lines with 2 spaces indentation)
            if ($line -match "^  ([\w-]+):$") {
                $currentTrack = $matches[1]
                $tracks[$currentTrack] = @{
                    name = $currentTrack
                    key = ""
                    gameVersion = ""
                    runtimeVersion = ""
                }
                continue
            }
            
            # Parse properties (looking for lines with 4 spaces indentation)
            if ($currentTrack -and $line -match "^    (\w+):\s*(.*)$") {
                $propertyName = $matches[1]
                $propertyValue = $matches[2].Trim("'")
                
                switch ($propertyName) {
                    "key" { $tracks[$currentTrack].key = $propertyValue }
                    "applicableGameVersion" { $tracks[$currentTrack].gameVersion = $propertyValue }
                    "runtimeVersion" { $tracks[$currentTrack].runtimeVersion = $propertyValue }
                }
            }
        }
    }

    # Display options
    Write-Host "`nAvailable branches:`n"
    $i = 1
    $options = @()
    foreach ($track in $tracks.GetEnumerator() | Sort-Object Name) {
        $keyDisplay = if ($track.Value.key) { $track.Value.key } else { "none" }
        Write-Host "$i. $($track.Key)"
        Write-Host "   Key: $keyDisplay"
        Write-Host "   Game Version: $($track.Value.gameVersion)"
        Write-Host "   Runtime: $($track.Value.runtimeVersion)`n"
        $options += $track.Value
        $i++
    }
    Write-Host "0. Cancel"

    Write-Host "`nPress a number to select an option..."

    # Get user input
    $choice = $null
    while ($choice -eq $null) {
        if ([Console]::KeyAvailable) {
            $keyInfo = [Console]::ReadKey($true)
            $keyChar = $keyInfo.KeyChar
            
            if ($keyChar -match '^\d$') {
                $choice = [int]::Parse($keyChar)
                Write-Host $choice
                
                if ($choice -eq 0) {
                    Write-Host "`nOperation cancelled."
                    exit
                }
                
                if ($choice -lt 1 -or $choice -gt $options.Count) {
                    Write-Host "`nInvalid choice."
                    $choice = $null
                    continue
                }
            }
        }
        Start-Sleep -Milliseconds 50
    }

    # Get the selected track
    $selectedTrack = $options[$choice - 1]

    # Path to dalamudConfig.json
    $configPath = "$env:APPDATA\XIVLauncher\dalamudConfig.json"

    # Check if file exists
    if (-not (Test-Path $configPath)) {
        Write-Host "dalamudConfig.json not found at $configPath"
        exit
    }

    # Read the original JSON file
    $originalJson = Get-Content $configPath -Raw
    
    # Update only the specific values while keeping the original formatting
    $config = $originalJson | ConvertFrom-Json
    $pattern1 = '"DalamudBetaKey"\s*:\s*(?:"[^"]*"|[^,}\s]+)'
    $pattern2 = '"DalamudBetaKind"\s*:\s*(?:"[^"]*"|[^,}\s]+)'
    
    $replacement1 = '"DalamudBetaKey": "' + $selectedTrack.key + '"'
    $replacement2 = '"DalamudBetaKind": "' + $selectedTrack.name + '"'
    
    $newJson = $originalJson
    $newJson = $newJson -replace $pattern1, $replacement1
    $newJson = $newJson -replace $pattern2, $replacement2

    # Save the modified JSON file
    [System.IO.File]::WriteAllText($configPath, $newJson)

    Write-Host "`nConfiguration updated successfully!"
    Write-Host "Branch: $($selectedTrack.name)"
    Write-Host "Key: $($selectedTrack.key)"
    Write-Host "Game Version: $($selectedTrack.gameVersion)"
    Write-Host "Runtime: $($selectedTrack.runtimeVersion)"

} catch {
    Write-Host "An error occurred:"
    Write-Host $_.Exception.Message
    Write-Host "`nStack trace:"
    Write-Host $_.Exception.StackTrace
}

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

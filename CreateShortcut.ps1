# Get the current directory
$currentDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

# Define paths
$targetPath = Join-Path $currentDir "DalamudBranchSwitcher.ps1"
$shortcutPath = Join-Path $currentDir "DalamudBranchSwitcher.lnk"
$iconPath = Join-Path $currentDir "icon.ico"

# Create a WScript Shell Object
$WScriptShell = New-Object -ComObject WScript.Shell

# Create the shortcut
$Shortcut = $WScriptShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = "powershell.exe"
$Shortcut.Arguments = "-ExecutionPolicy Bypass -NoProfile -File `"$targetPath`""
$Shortcut.WorkingDirectory = $currentDir

# Set icon if it exists
if (Test-Path $iconPath) {
    $Shortcut.IconLocation = $iconPath
}

# Save the shortcut
$Shortcut.Save()

Write-Host "Shortcut created successfully at: $shortcutPath"
if (-not (Test-Path $iconPath)) {
    Write-Host "Note: Icon file not found at: $iconPath"
    Write-Host "The shortcut will use the default PowerShell icon."
    Write-Host "To use a custom icon, place a .ico file named 'DalamudBranchSwitcher.ico' in the same folder."
}

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") 
# Ultra-Robust EFI HWID Spoofer - Main Dashboard
# Simplified interface with 6 buttons

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ProjectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    [System.Windows.Forms.MessageBox]::Show(
        "This application must run as Administrator.`n`nPlease right-click and select 'Run as Administrator'.",
        "Administrator Rights Required",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    exit 1
}

# Create main form
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "L2 HWID Spoofer - Dashboard"
$Form.Size = New-Object System.Drawing.Size(600, 550)
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "FixedDialog"
$Form.MaximizeBox = $false
$Form.BackColor = [System.Drawing.Color]::White

# Title Label
$TitleLabel = New-Object System.Windows.Forms.Label
$TitleLabel.Location = New-Object System.Drawing.Point(20, 20)
$TitleLabel.Size = New-Object System.Drawing.Size(560, 30)
$TitleLabel.Text = "L2 HWID Spoofer - Control Panel"
$TitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$TitleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$Form.Controls.Add($TitleLabel)

# Status Panel
$StatusGroup = New-Object System.Windows.Forms.GroupBox
$StatusGroup.Location = New-Object System.Drawing.Point(20, 60)
$StatusGroup.Size = New-Object System.Drawing.Size(560, 140)
$StatusGroup.Text = " System Status "
$StatusGroup.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$Form.Controls.Add($StatusGroup)

# Status Labels
$StatusY = 25

function Add-StatusLabel {
    param($Name, $Value, $Color)
    
    $nameLabel = New-Object System.Windows.Forms.Label
    $nameLabel.Location = New-Object System.Drawing.Point(20, $script:StatusY)
    $nameLabel.Size = New-Object System.Drawing.Size(200, 20)
    $nameLabel.Text = $Name
    $nameLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $StatusGroup.Controls.Add($nameLabel)
    
    $valueLabel = New-Object System.Windows.Forms.Label
    $valueLabel.Location = New-Object System.Drawing.Point(220, $script:StatusY)
    $valueLabel.Size = New-Object System.Drawing.Size(320, 20)
    $valueLabel.Text = $Value
    $valueLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $valueLabel.ForeColor = $Color
    $StatusGroup.Controls.Add($valueLabel)
    
    $script:StatusY += 25
    return $valueLabel
}

# Check statuses
$CertExists = Test-Path (Join-Path $ProjectRoot "02-Certificates\my-key.crt")
$SignedExists = Test-Path (Join-Path $ProjectRoot "01-EFI-Spoofer\spoofer-signed.efi")
$ShimExists = Test-Path (Join-Path $ProjectRoot "04-USB-Creator\bootloader\shimx64.efi")

$bootEntries = bcdedit /enum firmware 2>&1 | Out-String
$BootEntryExists = $bootEntries -match "L2signed"

try {
    $secureBootEnabled = Confirm-SecureBootUEFI
} catch {
    $secureBootEnabled = $null
}

# Add status items
$certText = if ($CertExists) { "[Generated]" } else { "[Not Found]" }
$certColor = if ($CertExists) { [System.Drawing.Color]::Green } else { [System.Drawing.Color]::Red }
$CertStatus = Add-StatusLabel "Certificate:" $certText $certColor

$spooferText = if ($SignedExists) { "[Signed]" } else { "[Unsigned]" }
$spooferColor = if ($SignedExists) { [System.Drawing.Color]::Green } else { [System.Drawing.Color]::Red }
$SpooferStatus = Add-StatusLabel "Spoofer Signature:" $spooferText $spooferColor

$UsbStatus = Add-StatusLabel "USB Status:" "[Manual Check]" ([System.Drawing.Color]::Gray)

$installText = if ($BootEntryExists) { "[Installed]" } else { "[Not Installed]" }
$installColor = if ($BootEntryExists) { [System.Drawing.Color]::Green } else { [System.Drawing.Color]::Red }
$InstallStatus = Add-StatusLabel "System Installation:" $installText $installColor

$sbText = if ($null -eq $secureBootEnabled) { "[Unknown]" } elseif ($secureBootEnabled) { "[Enabled]" } else { "[Disabled]" }
$sbColor = if ($secureBootEnabled) { [System.Drawing.Color]::Green } elseif ($null -eq $secureBootEnabled) { [System.Drawing.Color]::Gray } else { [System.Drawing.Color]::Orange }
$SecureBootStatus = Add-StatusLabel "Secure Boot:" $sbText $sbColor

# Buttons Panel
$ButtonsGroup = New-Object System.Windows.Forms.GroupBox
$ButtonsGroup.Location = New-Object System.Drawing.Point(20, 210)
$ButtonsGroup.Size = New-Object System.Drawing.Size(560, 250)
$ButtonsGroup.Text = " Actions "
$ButtonsGroup.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$Form.Controls.Add($ButtonsGroup)

# Button helper function
function Add-Button {
    param($Text, $X, $Y, $Width, $Height, $ScriptPath)
    
    $button = New-Object System.Windows.Forms.Button
    $button.Location = New-Object System.Drawing.Point($X, $Y)
    $button.Size = New-Object System.Drawing.Size($Width, $Height)
    $button.Text = $Text
    $button.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $button.FlatStyle = [System.Windows.Forms.FlatStyle]::System
    
    $button.Add_Click({
        $scriptToRun = $ScriptPath
        if (Test-Path $scriptToRun) {
            Start-Process powershell.exe -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$scriptToRun`"" -Verb RunAs
        } else {
            [System.Windows.Forms.MessageBox]::Show(
                "Script not found: $scriptToRun",
                "Error",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
        }
    }.GetNewClosure())
    
    $ButtonsGroup.Controls.Add($button)
    return $button
}

# Create 6 buttons (2 rows of 3)
$ButtonWidth = 170
$ButtonHeight = 50
$ButtonSpacingX = 185
$ButtonSpacingY = 70
$ButtonStartX = 15
$ButtonStartY = 30

# Row 1
$Btn1 = Add-Button "1. Generate Certificate" $ButtonStartX ($ButtonStartY) $ButtonWidth $ButtonHeight (Join-Path $ProjectRoot "02-Certificates\generate-cert.ps1")
$Btn2 = Add-Button "2. Sign Spoofer" ($ButtonStartX + $ButtonSpacingX) ($ButtonStartY) $ButtonWidth $ButtonHeight (Join-Path $ProjectRoot "03-Signing\sign-spoofer.ps1")
$Btn3 = Add-Button "3. Create USB" ($ButtonStartX + $ButtonSpacingX * 2) ($ButtonStartY) $ButtonWidth $ButtonHeight (Join-Path $ProjectRoot "04-USB-Creator\create-usb.ps1")

# Row 2
$Btn4 = Add-Button "4. Install to System" $ButtonStartX ($ButtonStartY + $ButtonSpacingY) $ButtonWidth $ButtonHeight (Join-Path $ProjectRoot "05-System-Installer\install-to-system.ps1")
$Btn5 = Add-Button "5. Check Status" ($ButtonStartX + $ButtonSpacingX) ($ButtonStartY + $ButtonSpacingY) $ButtonWidth $ButtonHeight (Join-Path $ProjectRoot "05-System-Installer\verify-install.ps1")
$Btn6 = Add-Button "6. Uninstall" ($ButtonStartX + $ButtonSpacingX * 2) ($ButtonStartY + $ButtonSpacingY) $ButtonWidth $ButtonHeight (Join-Path $ProjectRoot "05-System-Installer\uninstall.ps1")

# Refresh button
$RefreshButton = New-Object System.Windows.Forms.Button
$RefreshYPos = $ButtonStartY + $ButtonSpacingY * 2 - 10
$RefreshButton.Location = New-Object System.Drawing.Point($ButtonStartX, $RefreshYPos)
$RefreshButton.Size = New-Object System.Drawing.Size(530, 35)
$RefreshButton.Text = "Refresh Status"
$RefreshButton.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$RefreshButton.FlatStyle = [System.Windows.Forms.FlatStyle]::System

$RefreshButton.Add_Click({
    # Re-check statuses
    $CertExists = Test-Path (Join-Path $ProjectRoot "02-Certificates\my-key.crt")
    $SignedExists = Test-Path (Join-Path $ProjectRoot "01-EFI-Spoofer\spoofer-signed.efi")
    
    $bootEntries = bcdedit /enum firmware 2>&1 | Out-String
    $BootEntryExists = $bootEntries -match "L2signed"
    
    try {
        $secureBootEnabled = Confirm-SecureBootUEFI
    } catch {
        $secureBootEnabled = $null
    }
    
    # Update labels
    $CertStatus.Text = if ($CertExists) { "[Generated]" } else { "[Not Found]" }
    $CertStatus.ForeColor = if ($CertExists) { [System.Drawing.Color]::Green } else { [System.Drawing.Color]::Red }
    
    $SpooferStatus.Text = if ($SignedExists) { "[Signed]" } else { "[Unsigned]" }
    $SpooferStatus.ForeColor = if ($SignedExists) { [System.Drawing.Color]::Green } else { [System.Drawing.Color]::Red }
    
    $InstallStatus.Text = if ($BootEntryExists) { "[Installed]" } else { "[Not Installed]" }
    $InstallStatus.ForeColor = if ($BootEntryExists) { [System.Drawing.Color]::Green } else { [System.Drawing.Color]::Red }
    
    $SecureBootStatus.Text = if ($null -eq $secureBootEnabled) { "[Unknown]" } elseif ($secureBootEnabled) { "[Enabled]" } else { "[Disabled]" }
    $SecureBootStatus.ForeColor = if ($secureBootEnabled) { [System.Drawing.Color]::Green } elseif ($null -eq $secureBootEnabled) { [System.Drawing.Color]::Gray } else { [System.Drawing.Color]::Orange }
    
    [System.Windows.Forms.MessageBox]::Show(
        "Status refreshed!",
        "Refresh Complete",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
}.GetNewClosure())

$ButtonsGroup.Controls.Add($RefreshButton)

# Footer
$FooterLabel = New-Object System.Windows.Forms.Label
$FooterLabel.Location = New-Object System.Drawing.Point(20, 470)
$FooterLabel.Size = New-Object System.Drawing.Size(560, 40)
$FooterLabel.Text = "Workflow: Generate Certificate -> Sign Spoofer -> Create USB -> Test USB -> Install to System`nSee WORKFLOW.md for detailed instructions"
$FooterLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$FooterLabel.ForeColor = [System.Drawing.Color]::Gray
$FooterLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$Form.Controls.Add($FooterLabel)

# Show form
$Form.ShowDialog() | Out-Null



# GUI installer for daves-tools. Visual wizard that mirrors Install-DavesTools.ps1
# step-by-step with a live log, a step indicator, and a progress bar. Run as:
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File toolkit/Install-DavesTools-GUI.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File toolkit/Install-DavesTools-GUI.ps1 -InstallPath C:\daves-tools
#
# Steps:
#   1. Welcome   2. License   3. Install Location   4. Components
#   5. Prerequisites   6. Install (live log)   7. Complete
#
# Each install step is wired to the same primitive as Install-DavesTools.ps1
# so the GUI shows what is actually happening on disk.
[CmdletBinding()]
param(
    [string]$InstallPath = '',
    [string]$Version = '1.4.0'
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# -----------------------------------------------------------------------------
# Color palette and font
# -----------------------------------------------------------------------------
$bgDark      = [System.Drawing.Color]::FromArgb(30, 30, 30)
$bgPanel     = [System.Drawing.Color]::FromArgb(45, 45, 48)
$bgContent   = [System.Drawing.Color]::FromArgb(37, 37, 38)
$fgText      = [System.Drawing.Color]::FromArgb(230, 230, 230)
$fgMuted     = [System.Drawing.Color]::FromArgb(150, 150, 150)
$accent      = [System.Drawing.Color]::FromArgb(78, 201, 176)
$good        = [System.Drawing.Color]::FromArgb(120, 220, 140)
$warn        = [System.Drawing.Color]::FromArgb(255, 200, 80)
$bad         = [System.Drawing.Color]::FromArgb(255, 110, 110)
$border      = [System.Drawing.Color]::FromArgb(60, 60, 65)

$fontTitle   = New-Object System.Drawing.Font('Segoe UI Semibold', 16, [System.Drawing.FontStyle]::Bold)
$fontHeader  = New-Object System.Drawing.Font('Segoe UI Semibold', 12, [System.Drawing.FontStyle]::Bold)
$fontBody    = New-Object System.Drawing.Font('Segoe UI', 9.5)
$fontSmall   = New-Object System.Drawing.Font('Segoe UI', 8.5)
$fontLog     = New-Object System.Drawing.Font('Consolas', 9)
$fontStep    = New-Object System.Drawing.Font('Segoe UI', 10)

# Promote palette + fonts into script scope so functions can see them
$script:bgDark = $bgDark
$script:bgPanel = $bgPanel
$script:bgContent = $bgContent
$script:fgText = $fgText
$script:fgMuted = $fgMuted
$script:accent = $accent
$script:good = $good
$script:warn = $warn
$script:bad = $bad
$script:border = $border
$script:fontTitle = $fontTitle
$script:fontHeader = $fontHeader
$script:fontBody = $fontBody
$script:fontSmall = $fontSmall
$script:fontLog = $fontLog
$script:fontStep = $fontStep

# -----------------------------------------------------------------------------
# Resolve install path. Default to %LOCALAPPDATA%\Programs\daves-tools on first
# run; remember the last choice in HKCU for the next time.
# -----------------------------------------------------------------------------
$regKey      = 'HKCU:\Software\daves-tools'
if (-not $InstallPath) {
    if (Test-Path $regKey) {
        $InstallPath = (Get-ItemProperty -Path $regKey -Name 'InstallPath' -ErrorAction SilentlyContinue).InstallPath
    }
    if (-not $InstallPath) {
        $InstallPath = Join-Path -Path $env:LOCALAPPDATA -ChildPath 'Programs\daves-tools'
    }
}

# -----------------------------------------------------------------------------
# The 7 installer steps. Each entry: title, description, action scriptblock (optional).
# The action runs during the Install step (Step 5) and drives the step indicators.
# -----------------------------------------------------------------------------
$script:Steps = @(
    @{ Name = 'Welcome';            Title = 'Welcome';                  Desc = 'Get introduced to daves-tools v' + $Version + '.';                          Action = $null }
    @{ Name = 'License';            Title = 'License';                  Desc = 'Review and accept the MIT license.';                                       Action = $null }
    @{ Name = 'InstallPath';        Title = 'Install Location';         Desc = 'Choose where to install daves-tools.';                                     Action = $null }
    @{ Name = 'Components';         Title = 'Components';               Desc = 'Pick what to install (defaults recommended).';                             Action = $null }
    @{ Name = 'Prerequisites';      Title = 'Prerequisites';            Desc = 'Verify Node.js, npm, Python, and git are installed.';                      Action = $null }
    @{ Name = 'Install';            Title = 'Installing';               Desc = 'Running the install steps against your machine.';                          Action = $null }
    @{ Name = 'Complete';           Title = 'Complete';                 Desc = 'Installation summary and next steps.';                                    Action = $null }
)

# Per-component install definitions. Each runs as one step in the Install phase.
$script:Components = @(
    @{ Id = 'core';       Name = 'Core harness + registry + scripts';         Default = $true;  Critical = $true;  Cmd = 'CoreInstall'    }
    @{ Id = 'service';    Name = 'Windows service for MCP watchdog';           Default = $true;  Critical = $false; Cmd = 'ServiceInstall' }
    @{ Id = 'watchdog';   Name = 'LM Studio auto-restart scheduled task';       Default = $true;  Critical = $false; Cmd = 'WatchdogInstall' }
    @{ Id = 'ide';        Name = 'IDE configs (Claude Desktop / Codex / Kilo / Devin)'; Default = $true;  Critical = $false; Cmd = 'IdeInstall' }
    @{ Id = 'secrets';    Name = 'Create configs\secrets.json from example';   Default = $true;  Critical = $false; Cmd = 'SecretInstall' }
)

# -----------------------------------------------------------------------------
# Main window
# -----------------------------------------------------------------------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "daves-tools v$Version Setup"
$form.Size = New-Object System.Drawing.Size(820, 580)
$form.MinimumSize = New-Object System.Drawing.Size(820, 580)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.BackColor = $bgDark
$form.ForeColor = $fgText
$form.Font = $fontBody

# Banner drawn programmatically (no external image assets)
$banner = New-Object System.Windows.Forms.Panel
$banner.Location = New-Object System.Drawing.Point(0, 0)
$banner.Size = New-Object System.Drawing.Size(820, 84)
$banner.BackColor = $bgPanel
$banner.Add_Paint({
    $g = $e.Graphics
    $g.SmoothingMode = 'AntiAlias'
    # Left accent bar
    $brush = New-Object System.Drawing.SolidBrush($accent)
    $g.FillRectangle($brush, 0, 0, 6, 84)
    # Wordmark
    $textBrush = New-Object System.Drawing.SolidBrush($fgText)
    $titleFont = New-Object System.Drawing.Font('Segoe UI Semibold', 22, [System.Drawing.FontStyle]::Bold)
    $g.DrawString('daves-tools', $titleFont, $textBrush, 24, 14)
    $subtitleFont = New-Object System.Drawing.Font('Segoe UI', 10)
    $g.DrawString("v$Version — MCP orchestration harness for Windows", $subtitleFont, $textBrush, 26, 50)
})

# Step indicator panel (left column)
$stepsList = New-Object System.Windows.Forms.Panel
$stepsList.Location = New-Object System.Drawing.Point(0, 84)
$stepsList.Size = New-Object System.Drawing.Size(220, 416)
$stepsList.BackColor = $bgPanel

$stepLabels = @()
$script:StepSpacing = 56
for ($i = 0; $i -lt $script:Steps.Count; $i++) {
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Location = New-Object System.Drawing.Point(20, 18 + ($i * $script:StepSpacing))
    $lbl.Size = New-Object System.Drawing.Size(180, 40)
    $lbl.Font = $fontStep
    $lbl.ForeColor = $fgMuted
    $lbl.BackColor = $bgPanel
    $lbl.Text = ('○ {0}. {1}' -f ($i + 1), $script:Steps[$i].Title)
    $lbl.TextAlign = 'MiddleLeft'
    $stepsList.Controls.Add($lbl)
    $stepLabels += $lbl
}

# Content panel (right column, holds the currently active step's controls)
$content = New-Object System.Windows.Forms.Panel
$content.Location = New-Object System.Drawing.Point(220, 84)
$content.Size = New-Object System.Drawing.Size(600, 416)
$content.BackColor = $bgContent

# Footer panel (progress bar + buttons)
$footer = New-Object System.Windows.Forms.Panel
$footer.Location = New-Object System.Drawing.Point(0, 500)
$footer.Size = New-Object System.Drawing.Size(820, 80)
$footer.BackColor = $bgPanel

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(20, 16)
$progressBar.Size = New-Object System.Drawing.Size(580, 22)
$progressBar.Style = 'Continuous'
$progressBar.Minimum = 0
$progressBar.Maximum = 100
$progressBar.Value = 0

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Location = New-Object System.Drawing.Point(20, 44)
$statusLabel.Size = New-Object System.Drawing.Size(580, 22)
$statusLabel.Font = $fontSmall
$statusLabel.ForeColor = $fgMuted
$statusLabel.Text = 'Ready.'

$btnBack = New-Object System.Windows.Forms.Button
$btnBack.Location = New-Object System.Drawing.Point(620, 16)
$btnBack.Size = New-Object System.Drawing.Size(90, 30)
$btnBack.Text = '< Back'
$btnBack.FlatStyle = 'Flat'
$btnBack.BackColor = $bgDark
$btnBack.ForeColor = $fgText
$btnBack.Enabled = $false
$btnBack.FlatAppearance.BorderColor = $border

$btnNext = New-Object System.Windows.Forms.Button
$btnNext.Location = New-Object System.Drawing.Point(720, 16)
$btnNext.Size = New-Object System.Drawing.Size(90, 30)
$btnNext.Text = 'Next >'
$btnNext.FlatStyle = 'Flat'
$btnNext.BackColor = $accent
$btnNext.ForeColor = $bgDark
$btnNext.FlatAppearance.BorderColor = $accent

$btnCancel = New-Object System.Windows.Forms.Button
$btnCancel.Location = New-Object System.Drawing.Point(720, 50)
$btnCancel.Size = New-Object System.Drawing.Size(90, 22)
$btnCancel.Text = 'Cancel'
$btnCancel.FlatStyle = 'Flat'
$btnCancel.BackColor = $bgPanel
$btnCancel.ForeColor = $fgMuted
$btnCancel.FlatAppearance.BorderColor = $border

$footer.Controls.AddRange(@($progressBar, $statusLabel, $btnBack, $btnNext, $btnCancel))

$form.Controls.AddRange(@($banner, $stepsList, $content, $footer))

# -----------------------------------------------------------------------------
# Wizard state machine
# -----------------------------------------------------------------------------
$script:CurrentStep = 0
$script:SelectedComponents = @{}
foreach ($c in $script:Components) { $script:SelectedComponents[$c.Id] = $c.Default }
$script:InstallLog = New-Object System.Text.StringBuilder
$script:InstallSucceeded = $true
$script:InstallSummary = @()

function Set-StepIndicator {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([int]$Active)
    for ($i = 0; $i -lt $stepLabels.Count; $i++) {
        $glyph = if ($i -lt $Active) { '✓' }
                 elseif ($i -eq $Active) { '●' }
                 else { '○' }
        $color = if ($i -lt $Active) { $good }
                 elseif ($i -eq $Active) { $accent }
                 else { $fgMuted }
        $stepLabels[$i].Text = ('{0} {1}. {2}' -f $glyph, ($i + 1), $script:Steps[$i].Title)
        $stepLabels[$i].ForeColor = $color
    }
    if ($PSCmdlet.ShouldProcess('step indicators', 'update')) { }
}

function Clear-Panel {
    $content.Controls.Clear()
}

function Set-Status {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([string]$Text)
    $statusLabel.Text = $Text
    [System.Windows.Forms.Application]::DoEvents()
    if ($PSCmdlet.ShouldProcess('status label', 'set')) { }
}

function Write-Log {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([string]$Line, [System.Drawing.Color]$Color)
    if (-not $script:logBox) { return }
    $script:logBox.SelectionStart = $script:logBox.TextLength
    $script:logBox.SelectionLength = 0
    $script:logBox.SelectionColor = $Color
    $script:logBox.AppendText(($Line + "`r`n"))
    $script:logBox.SelectionColor = $script:logBox.ForeColor
    $script:logBox.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
    if ($PSCmdlet.ShouldProcess('log', 'append')) { }
}

function Show-Step {
    param([int]$Index)
    $script:CurrentStep = $Index
    Clear-Panel
    Set-StepIndicator -Active $Index
    Set-Status $script:Steps[$Index].Desc

    switch ($script:Steps[$Index].Name) {
        'Welcome'         { Show-Welcome }
        'License'         { Show-License }
        'InstallPath'     { Show-InstallPath }
        'Components'      { Show-Component }
        'Prerequisites'   { Show-Prerequisite }
        'Install'         { Show-Install }
        'Complete'        { Show-Complete }
    }

    $btnBack.Enabled = ($Index -gt 0) -and ($script:Steps[$Index].Name -ne 'Install')
    if ($script:Steps[$Index].Name -eq 'Install' -or $script:Steps[$Index].Name -eq 'Complete') {
        $btnNext.Text = if ($script:Steps[$Index].Name -eq 'Complete') { 'Finish' } else { 'Install' }
    } else {
        $btnNext.Text = 'Next >'
    }
}

# -----------------------------------------------------------------------------
# Step renderers
# -----------------------------------------------------------------------------
function Add-Label {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPositionalParameters', '', Justification = 'Positional layout is intentional and unambiguous within the wizard')]
    param(
        [Parameter(Position = 0)] [int]$X,
        [Parameter(Position = 1)] [int]$Y,
        [Parameter(Position = 2)] [int]$W,
        [Parameter(Position = 3)] [int]$H,
        [Parameter(Position = 4)] [string]$Text,
        [Parameter(Position = 5)] [System.Drawing.Font]$Font = $null,
        [Parameter(Position = 6)] [System.Drawing.Color]$Color = $null
    )
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Location = New-Object System.Drawing.Point($X, $Y)
    $lbl.Size = New-Object System.Drawing.Size($W, $H)
    $lbl.Text = $Text
    $lbl.Font = if ($Font) { $Font } else { $fontBody }
    $lbl.ForeColor = if ($Color) { $Color } else { $fgText }
    $lbl.BackColor = $bgContent
    $content.Controls.Add($lbl)
    return $lbl
}

function Show-Welcome {
    Add-Label -X 24 -Y 18 -W 560 -H 40 -Text 'Welcome to daves-tools' -Font $fontTitle
    Add-Label -X 24 -Y 64 -W 560 -H 24 -Text $Version -Font $fontHeader -Color $accent
    Add-Label -X 24 -Y 110 -W 560 -H 60 -Text 'A typed, certifiable, Windows-first harness for MCP servers, skill packs, and dependencies that power local-first AI workflows.' -Font $fontBody
    Add-Label -X 24 -Y 180 -W 560 -H 24 -Text 'This installer will:' -Font $fontHeader
    $bullets = @(
        '  •  Copy the harness, scripts, registry, and docs to your install location'
        '  •  Install Node dependencies for the harness'
        '  •  Optionally register the MCP watchdog as a Windows service'
        '  •  Optionally register the LM Studio auto-restart scheduled task'
        '  •  Optionally write IDE configs (Claude Desktop / Codex / Kilo / Devin)'
        '  •  Verify the install with the same gates used in CI'
    )
    $y = 210
    foreach ($b in $bullets) { Add-Label -X 36 -Y $y -W 560 -H 22 -Text $b; $y += 22 }
    Add-Label -X 24 -Y $y -W 560 -H 24 -Text 'Click Next to continue.' -Font $fontBody -Color $fgMuted
}

function Show-License {
    Add-Label -X 24 -Y 18 -W 560 -H 28 -Text 'License Agreement' -Font $fontTitle
    Add-Label -X 24 -Y 52 -W 560 -H 22 -Text 'Please read the license before installing.' -Font $fontSmall -Color $fgMuted

    $license = New-Object System.Windows.Forms.TextBox
    $license.Location = New-Object System.Drawing.Point(24, 84)
    $license.Size = New-Object System.Drawing.Size(552, 240)
    $license.Multiline = $true
    $license.ReadOnly = $true
    $license.ScrollBars = 'Vertical'
    $license.BackColor = $bgPanel
    $license.ForeColor = $fgText
    $license.Font = $fontBody
    $license.BorderStyle = 'FixedSingle'
    $license.Text = @"
MIT License

Copyright (c) 2026 daves-tools contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"@
    $content.Controls.Add($license)

    $accept = New-Object System.Windows.Forms.CheckBox
    $accept.Location = New-Object System.Drawing.Point(24, 336)
    $accept.Size = New-Object System.Drawing.Size(400, 24)
    $accept.Text = 'I accept the license terms'
    $accept.Font = $fontBody
    $accept.ForeColor = $fgText
    $accept.BackColor = $bgContent
    $accept.Add_CheckedChanged({
        $btnNext.Enabled = $accept.Checked
    })
    $content.Controls.Add($accept)
    $btnNext.Enabled = $false
}

function Show-InstallPath {
    Add-Label -X 24 -Y 18 -W 560 -H 28 -Text 'Choose Install Location' -Font $fontTitle
    Add-Label -X 24 -Y 52 -W 560 -H 22 -Text 'The install path is where the harness, scripts, registry, and docs will live.' -Font $fontSmall -Color $fgMuted

    Add-Label -X 24 -Y 90 -W 100 -H 24 -Text 'Install to:' -Font $fontBody
    $pathBox = New-Object System.Windows.Forms.TextBox
    $pathBox.Location = New-Object System.Drawing.Point(120, 88)
    $pathBox.Size = New-Object System.Drawing.Size(380, 26)
    $pathBox.BackColor = $bgPanel
    $pathBox.ForeColor = $fgText
    $pathBox.Font = $fontBody
    $pathBox.BorderStyle = 'FixedSingle'
    $pathBox.Text = $script:InstallPath
    $pathBox.Add_TextChanged({
        $script:InstallPath = $pathBox.Text
    })
    $content.Controls.Add($pathBox)

    $browse = New-Object System.Windows.Forms.Button
    $browse.Location = New-Object System.Drawing.Point(508, 87)
    $browse.Size = New-Object System.Drawing.Size(80, 28)
    $browse.Text = 'Browse...'
    $browse.FlatStyle = 'Flat'
    $browse.BackColor = $bgPanel
    $browse.ForeColor = $fgText
    $browse.FlatAppearance.BorderColor = $border
    $browse.Add_Click({
        $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
        $dlg.Description = 'Pick the install location'
        $dlg.SelectedPath = $script:InstallPath
        if ($dlg.ShowDialog($form) -eq 'OK') {
            $pathBox.Text = $dlg.SelectedPath
        }
    })
    $content.Controls.Add($browse)

    Add-Label -X 24 -Y 130 -W 560 -H 24 -Text 'Recommended: ' -Font $fontSmall -Color $fgMuted
    $disk = [System.IO.DriveInfo]::new((Split-Path -Path $script:InstallPath -Qualifier))
    Add-Label -X 24 -Y 152 -W 560 -H 22 -Text 'Drive {0} — {1} free' -Font $disk -Color $disk
    Add-Label -X 24 -Y 174 -W 560 -H 60 -Text 'The installer will write to this directory. On Windows, you typically want a path you control (e.g., %LOCALAPPDATA%\Programs\daves-tools or C:\daves-tools).' -Font $fontBody
}

function Show-Component {
    Add-Label -X 24 -Y 18 -W 560 -H 28 -Text 'Choose Components' -Font $fontTitle
    Add-Label -X 24 -Y 52 -W 560 -H 22 -Text 'Defaults recommended. Uncheck anything you do not want installed.' -Font $fontSmall -Color $fgMuted

    $list = New-Object System.Windows.Forms.CheckedListBox
    $list.Location = New-Object System.Drawing.Point(24, 88)
    $list.Size = New-Object System.Drawing.Size(552, 220)
    $list.BackColor = $bgPanel
    $list.ForeColor = $fgText
    $list.Font = $fontBody
    $list.BorderStyle = 'FixedSingle'
    $list.CheckOnClick = $true
    $list.IntegralHeight = $false
    foreach ($c in $script:Components) {
        $idx = $list.Items.Add($c.Name)
        if ($script:SelectedComponents[$c.Id]) { $list.SetItemChecked($idx, $true) } else { $list.SetItemChecked($idx, $false) }
    }
    $list.Add_ItemCheck({
        $id = $script:Components[$e.Index].Id
        if ($script:Components[$e.Index].Critical -and -not $e.NewValue -eq 'Checked') {
            [System.Windows.Forms.MessageBox]::Show(
                ('"{0}" is required for the harness to function.' -f $script:Components[$e.Index].Name),
                'Required component',
                'OK',
                'Warning')
            $e.NewValue = [System.Windows.Forms.CheckState]::Checked
            return
        }
        $script:SelectedComponents[$id] = ($e.NewValue -eq 'Checked')
    })
    $content.Controls.Add($list)

    Add-Label -X 24 -Y 320 -W 560 -H 80 -Text 'After Install-DavesTools.ps1 finishes, the selected components will run in order. Each step shows its live command output below as it executes.' -Font $fontBody -Color $fgMuted
}

function Show-Prerequisite {
    Add-Label -X 24 -Y 18 -W 560 -H 28 -Text 'Checking Prerequisites' -Font $fontTitle
    Add-Label -X 24 -Y 52 -W 560 -H 22 -Text 'These must be on PATH before the install can succeed.' -Font $fontSmall -Color $fgMuted

    $checks = @(
        @{ Id = 'node';    Name = 'Node.js';                MinMajor = 18; Cmd = 'node --version' }
        @{ Id = 'npm';     Name = 'npm';                    MinMajor = 0;  Cmd = 'npm --version' }
        @{ Id = 'python';  Name = 'Python (3.x)';           MinMajor = 3;  Cmd = 'python --version' }
        @{ Id = 'git';     Name = 'Git';                    MinMajor = 0;  Cmd = 'git --version' }
    )

    $tableHost = New-Object System.Windows.Forms.Panel
    $tableHost.Location = New-Object System.Drawing.Point(24, 88)
    $tableHost.Size = New-Object System.Drawing.Size(552, 160)
    $tableHost.BackColor = $bgPanel

    $y = 8
    foreach ($c in $checks) {
        $row = New-Object System.Windows.Forms.Label
        $row.Location = New-Object System.Drawing.Point(12, $y)
        $row.Size = New-Object System.Drawing.Size(528, 28)
        $row.Font = $fontBody
        $row.ForeColor = $fgText
        $row.BackColor = $bgPanel
        $row.TextAlign = 'MiddleLeft'
        $row.Text = ('  Checking {0}...   ' -f $c.Name)
        $tableHost.Controls.Add($row)
        $c.UILabel = $row
        $y += 32
    }
    $content.Controls.Add($tableHost)

    $rerun = New-Object System.Windows.Forms.Button
    $rerun.Location = New-Object System.Drawing.Point(24, 260)
    $rerun.Size = New-Object System.Drawing.Size(140, 28)
    $rerun.Text = 'Re-check'
    $rerun.FlatStyle = 'Flat'
    $rerun.BackColor = $bgPanel
    $rerun.ForeColor = $fgText
    $rerun.FlatAppearance.BorderColor = $border
    $rerun.Add_Click({
        foreach ($c in $checks) { Invoke-PrereqCheck -Check $c }
    })
    $content.Controls.Add($rerun)

    Add-Label -X 24 -Y 300 -W 560 -H 80 -Text 'Click Re-check after installing any missing prerequisites, then Next to proceed.' -Font $fontBody -Color $fgMuted

    # Run the checks once when the page is shown
    foreach ($c in $checks) { Invoke-PrereqCheck -Check $c }
}

function Invoke-PrereqCheck {
    param($Check)
    Set-Status ('Checking ' + $Check.Name + '...')
    $Check.UILabel.Text = ('  ●  Checking {0}...   ' -f $Check.Name)
    $Check.UILabel.ForeColor = $accent
    [System.Windows.Forms.Application]::DoEvents()

    $ok = $false
    $ver = ''
    try {
        $ver = (& cmd.exe /c $Check.Cmd 2>$null) -join ' '
        $ver = $ver.Trim()
        if ($Check.MinMajor -gt 0 -and $ver -match '(\d+)\.') {
            $major = [int]$Matches[1]
            if ($major -lt $Check.MinMajor) { $ver = "$ver (below required major $($Check.MinMajor))" }
            else { $ok = $true }
        } elseif ($ver) { $ok = $true }
    } catch {
        Write-Output "Prereq check '$($Check.Name)' threw: $($_.Exception.Message)"
    }

    if ($ok) {
        $Check.UILabel.Text = ('  ✓  {0,-22} {1}' -f $Check.Name + '   found', $ver)
        $Check.UILabel.ForeColor = $good
    } else {
        $Check.UILabel.Text = ('  ✗  {0,-22} not found' -f $Check.Name)
        $Check.UILabel.ForeColor = $bad
    }
    $statusText = if ($ok) { 'ok' } else { 'missing' }
    Set-Status ('Prereq ' + $Check.Name + ': ' + $statusText)
}

function Show-Install {
    Add-Label -X 24 -Y 18 -W 560 -H 28 -Text 'Installing' -Font $fontTitle
    Add-Label -X 24 -Y 52 -W 560 -H 22 -Text 'Live log below — each component shows its command and output as it runs.' -Font $fontSmall -Color $fgMuted

    $script:logBox = New-Object System.Windows.Forms.RichTextBox
    $script:logBox.Location = New-Object System.Drawing.Point(24, 84)
    $script:logBox.Size = New-Object System.Drawing.Size(552, 260)
    $script:logBox.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 22)
    $script:logBox.ForeColor = $fgText
    $script:logBox.Font = $fontLog
    $script:logBox.BorderStyle = 'FixedSingle'
    $script:logBox.ReadOnly = $true
    $script:logBox.ScrollBars = 'Vertical'
    $content.Controls.Add($script:logBox)
    Add-Label -X 24 -Y 354 -W 560 -H 30 -Text 'You can cancel below to stop after the current component finishes.' -Font $fontSmall -Color $fgMuted

    # Disable navigation during install
    $btnBack.Enabled = $false
    $btnNext.Enabled = $false

    # Run install asynchronously so the UI stays responsive
    $worker = New-Object System.ComponentModel.BackgroundWorker
    $worker.WorkerReportsProgress = $true
    $worker.Add_DoWork({
        try {
            Invoke-InstallSequence
        } catch {
            $script:InstallSucceeded = $false
            Write-Log ("INSTALL ERROR: " + $_.Exception.Message) $bad
        }
    })
    $worker.Add_RunWorkerCompleted({
        $script:CurrentStep = 6
        Show-Step -Index 6
    })
    $worker.RunWorkerAsync()
}

function Invoke-InstallSequence {
    $steps = @()
    foreach ($c in $script:Components) {
        if ($script:SelectedComponents[$c.Id]) {
            $steps += $c
        }
    }
    $total = $steps.Count + 1  # +1 for the copy step
    $done = 0

    Write-Log ('[1/' + $total + '] Copying daves-tools files to ' + $script:InstallPath + '...') $accent
    Set-Status 'Copying files...'
    try {
        if (Test-Path $script:InstallPath) {
            $existing = (Get-ChildItem -LiteralPath $script:InstallPath -ErrorAction SilentlyContinue | Measure-Object).Count
            if ($existing -gt 0) {
                Write-Log ('      Existing install detected (' + $existing + ' items). Refreshing files in place.') $fgMuted
            }
        } else {
            New-Item -ItemType Directory -Path $script:InstallPath -Force | Out-Null
        }
        # Use robocopy for each major directory
        $repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..')).Path
        foreach ($sub in @('toolkit','harness','configs','docs','mcp-manager','skills')) {
            $src = Join-Path $repoRoot $sub
            $dst = Join-Path $script:InstallPath $sub
            if (Test-Path $src) {
                if (Test-Path $dst) { Remove-Item -Recurse -Force $dst }
                robocopy $src $dst /MIR /NJH /NJS /NC /NDL /NFL /NP /XD node_modules daemon logs /R:0 /W:0 | Out-Null
                Write-Log ('      Copied ' + $sub + '/') $fgMuted
            }
        }
        foreach ($f in @('README.md','AGENTS.md','CHANGELOG.md','.gitlab-ci.yml','.gitignore')) {
            $src = Join-Path $repoRoot $f
            $dst = Join-Path $script:InstallPath $f
            if (Test-Path $src) { Copy-Item -LiteralPath $src -Destination $dst -Force; Write-Log ('      Copied ' + $f) $fgMuted }
        }
        # Persist install path for next launch
        if (-not (Test-Path $regKey)) { New-Item -Path $regKey -Force | Out-Null }
        Set-ItemProperty -Path $regKey -Name 'InstallPath' -Value $script:InstallPath
        $script:InstallSummary += 'Files copied to ' + $script:InstallPath
        Write-Log ('      Wrote HKCU\Software\daves-tools\InstallPath for next launch.') $fgMuted
    } catch {
        $script:InstallSucceeded = $false
        Write-Log ('      FAILED: ' + $_.Exception.Message) $bad
    }
    $done++
    $progressBar.Value = [int](($done / $total) * 100)

    # Per-component installs
    foreach ($c in $steps) {
        Write-Log ('[' + ($done + 1) + '/' + $total + '] ' + $c.Name + '...') $accent
        Set-Status ('Installing: ' + $c.Name)
        try {
            switch ($c.Cmd) {
                'CoreInstall'    { Install-Core }
                'ServiceInstall' { Install-Service }
                'WatchdogInstall' { Install-Watchdog }
                'IdeInstall'      { Install-Ide }
                'SecretInstall'  { Install-Secret }
            }
            $script:InstallSummary += 'OK: ' + $c.Name
        } catch {
            $script:InstallSucceeded = $false
            Write-Log ('      FAILED: ' + $_.Exception.Message) $bad
            $script:InstallSummary += 'FAILED: ' + $c.Name + ' — ' + $_.Exception.Message
        }
        $done++
        $progressBar.Value = [int](($done / $total) * 100)
    }

    Write-Log '' $fgText
    if ($script:InstallSucceeded) {
        Write-Log ('Install complete. ' + $script:InstallSummary.Count + ' steps succeeded.') $good
    } else {
        Write-Log ('Install finished with errors. See above.') $warn
    }
}

function Install-Core {
    Set-Location $script:InstallPath
    Write-Log ('      $ cd ' + $script:InstallPath) $fgMuted
    if (-not (Test-Path 'logs')) { New-Item -ItemType Directory -Path 'logs' | Out-Null; Write-Log ('      Created logs/') $fgMuted }
    Write-Log ('      $ npm install (harness deps)') $fgMuted
    Push-Location 'harness'
    try {
        # PSScriptAnalyzer: positional - intentional, npm accepts args positionally
        $out = & 'npm.cmd' install --no-audit --no-fund 2>&1 | Out-String
        Write-Log ($out.Trim()) $fgText
    } finally { Pop-Location }
    Write-Log ('      $ node harness/certifier.js --profile CORE') $fgMuted
    $out = & node harness/certifier.js --profile CORE 2>&1 | Out-String
    Write-Log ($out.Trim()) $fgText
}

function Install-Service {
    Set-Location $script:InstallPath
    Write-Log ('      $ powershell -File toolkit/Install-McpService.ps1') $fgMuted
    & powershell -NoProfile -ExecutionPolicy Bypass -File toolkit/Install-McpService.ps1 2>&1 | ForEach-Object { Write-Log ('      ' + $_) $fgText }
}

function Install-Watchdog {
    Set-Location $script:InstallPath
    Write-Log ('      $ powershell -File toolkit/Watch-LmStudio.ps1 -RegisterTask') $fgMuted
    & powershell -NoProfile -ExecutionPolicy Bypass -File toolkit/Watch-LmStudio.ps1 -RegisterTask 2>&1 | ForEach-Object { Write-Log ('      ' + $_) $fgText }
}

function Install-Ide {
    Set-Location $script:InstallPath
    Write-Log ('      $ powershell -File toolkit/Install-IdeConfigs.ps1') $fgMuted
    & powershell -NoProfile -ExecutionPolicy Bypass -File toolkit/Install-IdeConfigs.ps1 2>&1 | ForEach-Object { Write-Log ('      ' + $_) $fgText }
}

function Install-Secret {
    $src = Join-Path $script:InstallPath 'configs/secrets.example.json'
    $dst = Join-Path $script:InstallPath 'configs/secrets.json'
    if (Test-Path $src) {
        if (-not (Test-Path $dst)) {
            Copy-Item -LiteralPath $src -Destination $dst -Force
            Write-Log ('      Created configs\secrets.json from example. Edit it to add your real keys.') $good
        } else {
            Write-Log ('      configs\secrets.json already exists; left untouched.') $fgMuted
        }
    } else {
        Write-Log ('      No configs\secrets.example.json found; skipping.') $warn
    }
}

function Show-Complete {
    Add-Label -X 24 -Y 18 -W 560 -H 28 -Text 'Installation Complete' -Font $fontTitle
    if ($script:InstallSucceeded) {
        Add-Label -X 24 -Y 52 -W 560 -H 28 -Text 'daves-tools v' -Font $Version -Color ' installed successfully.'
    } else {
        Add-Label -X 24 -Y 52 -W 560 -H 28 -Text 'daves-tools v' -Font $Version -Color ' installed with errors.'
    }
    Add-Label -X 24 -Y 88 -W 560 -H 22 -Text 'Installed to: ' -Font $script -Color $fontBody
    Add-Label -X 24 -Y 116 -W 560 -H 22 -Text 'Summary:' -Font $fontHeader
    $y = 146
    foreach ($line in $script:InstallSummary) {
        $color = if ($line.StartsWith('OK:')) { $good } elseif ($line.StartsWith('FAILED:')) { $bad } else { $fgText }
        Add-Label -X 36 -Y $y -W 540 -H 20 -Text $line -Font $fontBody -Color $color
        $y += 20
    }
    Add-Label -X 24 -Y ($y + 12) -W 560 -H 60 -Text 'Next steps:' -Font $fontHeader
    Add-Label -X 36 -Y ($y + 36) -W 540 -H 22 -Text '  •  Open Claude Desktop / Codex / Kilo / Devin — IDE configs are wired'
    Add-Label -X 36 -Y ($y + 56) -W 540 -H 22 -Text '  •  LM Studio is auto-restarted by the registered scheduled task'
    Add-Label -X 36 -Y ($y + 76) -W 540 -H 22 -Text '  •  Re-run this installer any time to add or remove components'
    Add-Label -X 36 -Y ($y + 96) -W 540 -H 22 -Text ('  •  Logs and tool docs live in ' + $script:InstallPath + '\docs')
}

# -----------------------------------------------------------------------------
# Button handlers
# -----------------------------------------------------------------------------
$btnNext.Add_Click({
    switch ($script:Steps[$script:CurrentStep].Name) {
        'Welcome'         { Show-Step 1 }
        'License'         { Show-Step 2 }
        'InstallPath'     { Show-Step 3 }
        'Components'      { Show-Step 4 }
        'Prerequisites'   { Show-Step 5 }
        'Install'         { /* already running */ }
        'Complete'        { $form.Close() }
    }
})

$btnBack.Add_Click({
    if ($script:CurrentStep -gt 0) { Show-Step ($script:CurrentStep - 1) }
})

$btnCancel.Add_Click({
    if ($script:CurrentStep -eq 5) {
        Write-Log '' $fgText
        Write-Log 'Cancellation requested. Finishing current step, then exiting.' $warn
        $script:InstallSucceeded = $false
    } else {
        $confirm = [System.Windows.Forms.MessageBox]::Show(
            'Cancel the installation? Any files copied so far will be left in place.',
            'Confirm cancel',
            'YesNo',
            'Question')
        if ($confirm -eq 'Yes') { $form.Close() }
    }
})

# Initialize
Set-StepIndicator -Active 0
Show-Step 0

[System.Windows.Forms.Application]::EnableVisualStyles()
[void][System.Windows.Forms.Application]::Run($form)

[CmdletBinding()]
param(
    [string]$ReportPath = "C:\Users\Admin\CascadeProjects\daves-tools\docs\capability-report.json"
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$raw = [System.IO.File]::ReadAllText($ReportPath)
$report = $raw | ConvertFrom-Json

$form = New-Object System.Windows.Forms.Form
$form.Text = "DAVE-AI Operator Dashboard"
$form.Size = New-Object System.Drawing.Size(1200, 700)
$form.StartPosition = "CenterScreen"

$grid = New-Object System.Windows.Forms.DataGridView
$grid.Dock = "Fill"
$grid.AutoGenerateColumns = $false
$grid.AllowUserToAddRows = $false
$grid.ReadOnly = $true

$colName = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$colName.HeaderText = "Asset"
$colName.DataPropertyName = "display_name"
$colName.Width = 240
$grid.Columns.Add($colName)

$colType = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$colType.HeaderText = "Type"
$colType.DataPropertyName = "asset_type"
$colType.Width = 120
$grid.Columns.Add($colType)

$colHealthy = New-Object System.Windows.Forms.DataGridViewCheckBoxColumn
$colHealthy.HeaderText = "Healthy"
$colHealthy.DataPropertyName = "healthy"
$grid.Columns.Add($colHealthy)

$colInstall = New-Object System.Windows.Forms.DataGridViewCheckBoxColumn
$colInstall.HeaderText = "Install"
$colInstall.DataPropertyName = "install_ok"
$grid.Columns.Add($colInstall)

$colEnv = New-Object System.Windows.Forms.DataGridViewCheckBoxColumn
$colEnv.HeaderText = "Env"
$colEnv.DataPropertyName = "env_ok"
$grid.Columns.Add($colEnv)

$colProto = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$colProto.HeaderText = "Protocol"
$colProto.DataPropertyName = "protocol_ok"
$colProto.Width = 80
$grid.Columns.Add($colProto)

$colRepair = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$colRepair.HeaderText = "Repair"
$colRepair.DataPropertyName = "repair_actions"
$colRepair.Width = 400
$grid.Columns.Add($colRepair)

$grid.DataSource = $report.results
$form.Controls.Add($grid)

$panel = New-Object System.Windows.Forms.Panel
$panel.Dock = "Top"
$panel.Height = 40

$btnPreflight = New-Object System.Windows.Forms.Button
$btnPreflight.Text = "Run Preflight"
$btnPreflight.Width = 120
$btnPreflight.Left = 10
$btnPreflight.Top = 8
$btnPreflight.Add_Click({
    Start-Process powershell -ArgumentList "-NoExit -ExecutionPolicy Bypass -File `"C:\Users\Admin\CascadeProjects\daves-tools\toolkit\Run-Preflight.ps1`"" -WindowStyle Normal
})

$btnDoctor = New-Object System.Windows.Forms.Button
$btnDoctor.Text = "Refresh Doctor"
$btnDoctor.Width = 120
$btnDoctor.Left = 140
$btnDoctor.Top = 8
$btnDoctor.Add_Click({
    Start-Process powershell -ArgumentList "-NoExit -ExecutionPolicy Bypass -File `"C:\Users\Admin\CascadeProjects\daves-tools\toolkit\Capability-Doctor.ps1`"" -WindowStyle Normal
})

$btnCertify = New-Object System.Windows.Forms.Button
$btnCertify.Text = "Certify MCPs"
$btnCertify.Width = 120
$btnCertify.Left = 270
$btnCertify.Top = 8
$btnCertify.Add_Click({
    Start-Process powershell -ArgumentList "-NoExit -ExecutionPolicy Bypass -File `"C:\Users\Admin\CascadeProjects\daves-tools\toolkit\Certify-Mcps.ps1`"" -WindowStyle Normal
})

$lbl = New-Object System.Windows.Forms.Label
$lbl.Text = "Healthy: $($report.healthy) / $($report.total)"
$lbl.Left = 410
$lbl.Top = 12
$lbl.Width = 200

$panel.Controls.AddRange(@($btnPreflight, $btnDoctor, $btnCertify, $lbl))
$form.Controls.Add($panel)
$form.Controls.SetChildIndex($grid, 1)

[System.Windows.Forms.Application]::Run($form)

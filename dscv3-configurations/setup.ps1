<# 
    setup.ps1 - DSC v3 Deployment Script

    This script applies the AI configuration and the VS Code extensions configuration using DSC v3.
#>

# Verify that DSC v3 CLI is available.
if (-not (Get-Command dsc -ErrorAction SilentlyContinue)) {
    Write-Error "DSC v3 CLI not found. Please install DSC v3 (e.g. via Microsoft Store) and try again."
    exit 1
}

Write-Host "DSC v3 CLI found."

Break;

# Define paths.
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$aiConfig = Join-Path $ScriptRoot "configurations\ai-configuration.dsc.yaml"
$vscodeExtConfig = Join-Path $ScriptRoot "configurations\ai-configuration-vscode-extensions.json"

# Apply the AI configuration.
Write-Host "Applying AI configuration from $aiConfig..."
dsc apply $aiConfig
if ($LASTEXITCODE -ne 0) {
    Write-Error "AI configuration failed."
    exit $LASTEXITCODE
}

# Apply the VS Code Extensions configuration.
Write-Host "Applying VS Code Extensions configuration from $vscodeExtConfig..."
dsc apply $vscodeExtConfig
if ($LASTEXITCODE -ne 0) {
    Write-Error "VS Code Extensions configuration failed."
    exit $LASTEXITCODE
}

Write-Host "All DSC configurations applied successfully."

<# 
    Guidance on Utilizing DSC v3 Structured Output:

    • DSC v3 outputs structured JSON status for each resource, detailing its name, type, desired state, and any errors.
    • The dsc apply command returns a nonzero exit code if any resource fails to reach its desired state.
    • You can capture the output (e.g. using ConvertFrom-Json) to programmatically verify resource statuses.
    • Unlike PSDSC, DSC v3’s declarative YAML/JSON lets you clearly define dependencies (using dependsOn with resourceId) and assertions (to validate prerequisites) – making automated testing and validation simpler.
#>

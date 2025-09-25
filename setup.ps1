# List of available profile files in the /configurations sub-folder
$configurationsFolderPath = ".\configurations"
$profileFiles = @(Get-ChildItem -Path $configurationsFolderPath -Filter "*.dsc.yaml" | Select-Object -ExpandProperty Name)

$resourceTypeGroupIdentifier = 2
$resourceNameGroupIdentifier = 3
$resourceOutcomeGroupIdentifier = 4

function IsPowershellRunningWithAdminRights
{
    $currentUser = New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())
    if (!$currentUser.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator))
    {
        Write-Warning "Your not running Powershell with Administrator rights"
        return $false;
    }

    return $true;
}

function IsDSCv3Available {
    # Check if DSC v3 CLI is available
    try {
        $dscVersion = dsc --version 2>$null
        if ($dscVersion) {
            Write-Host "DSC v3 CLI found: $dscVersion" -ForegroundColor Green
            return $true
        }
    } catch {
        # DSC v3 not available
    }
    
    Write-Warning "DSC v3 CLI not found. Using WinGet for DSC v2 configurations."
    return $false
}

function IsConfigurationDSCv3 {
    param (
        [string]$configPath
    )
    
    $content = Get-Content $configPath -Raw
    return $content -match '\$schema.*dsc/schemas/v3'
}

function IsWingetVersionCorrect {
    param (
        [string]$requiredVersion = "1.7.10661"
    )

    $wingetVersionOutput = winget -v
    $currentVersion = $wingetVersionOutput.TrimStart('v')

    $currentVersionObject = [version]$currentVersion
    $requiredVersionObject = [version]$requiredVersion

    if ($currentVersionObject -lt $requiredVersionObject) {
        Write-Warning "WinGet is not at the required version or higher. Required: $requiredVersion, Current: $currentVersion"
        return $false
    }

    return $true
}

function Invoke-ProfileProcess {
    param (
        [string]
        $profilePath,

        [ValidateSet("Apply", "Test")]
        [string]
        $mode
    )
    Clear-Host

    $operationVerb = if ($mode -eq "Apply") { "Applying" } else { "Testing" }
    
    Write-Host "$operationVerb profile: " -NoNewline -ForegroundColor Yellow
    Write-Host $($profilePath)

    # Determine if this is a DSC v3 configuration
    $isDSCv3 = IsConfigurationDSCv3 -configPath $profilePath
    $isDSCv3Available = IsDSCv3Available
    
    if ($isDSCv3 -and $isDSCv3Available) {
        # Use DSC v3 CLI
        Write-Host "Using DSC v3 CLI..." -ForegroundColor Cyan
        
        if ($mode -eq "Apply") {
            $output = dsc config set -f $profilePath 2>&1
        } else {
            $output = dsc config test -f $profilePath 2>&1
        }
        
        Write-DSCv3Output -consoleOutput $output -mode $mode
    } elseif ($isDSCv3 -and -not $isDSCv3Available) {
        Write-Warning "This is a DSC v3 configuration but DSC v3 CLI is not available."
        Write-Warning "Please install DSC v3 CLI or use a DSC v2 configuration."
        return
    } else {
        # Use WinGet for DSC v2 configurations
        Write-Host "Using WinGet CLI for DSC v2 configuration..." -ForegroundColor Cyan
        $wingetCommand = if ($mode -eq "Apply") { "configure" } else { "configure test" }
        $output = Invoke-Expression "winget $wingetCommand -f `"$profilePath`" --accept-configuration-agreements" 2>&1
        Write-ConfigurationOutput -consoleOutput $output -mode $mode
    }
    
    Read-Host "Press Enter to continue..."
}

function Show-MainMenu {
    Clear-Host

    Write-Host "Available Profiles" -ForegroundColor Yellow
    for ($i = 0; $i -lt $profileFiles.Count; $i++) {
        Write-Host "$($i + 1). $($profileFiles[$i])"
    }

    Write-Host "0. Exit"
    $choice = Read-Host "Enter the number of the profile you want to test/apply (or '0' to exit)"
    return [int]$choice
}

function Show-SubMenu {
    param (
        [string]
        $selectedProfile
    )
    Clear-Host

    Write-Host "Selected Profile: " -NoNewline -ForegroundColor Yellow
    Write-Host $($selectedProfile)
    Write-Host "1. Run Profile"
    Write-Host "2. Test Profile"
    Write-Host "3. Return to Main Menu"
    Write-Host "0. Exit"
    $subChoice = Read-Host "Enter your choice (or '0' to exit)"
    return [int]$subChoice
}

function CalculateMaxLengths {
    param (
        [System.Text.RegularExpressions.MatchCollection]
        $lineMatches
    )

    $maxTypeLength = 0
    $maxNameLength = 0

    foreach ($lineMatch in $lineMatches) {
        $typeLength = $lineMatch.Groups[$resourceTypeGroupIdentifier].Value.Length
        $nameLength = $lineMatch.Groups[$resourceNameGroupIdentifier].Value.Length

        if ($typeLength -gt $maxTypeLength) { $maxTypeLength = $typeLength }
        if ($nameLength -gt $maxNameLength) { $maxNameLength = $nameLength }
    }

    return @{
        'MaxTypeLength' = $maxTypeLength;
        'MaxNameLength' = $maxNameLength
    }
}

function Write-OutputLine {
    param (
        [string]$type,
        [string]$name,
        [string]$status,
        [int]$maxTypeLength,
        [int]$maxNameLength,
        [string]$statusColor
    )

    $formattedType = $type.PadRight($maxTypeLength)
    $formattedName = $name.PadRight($maxNameLength)

    Write-Host $formattedType -NoNewline -ForegroundColor Yellow
    Write-Host " [$formattedName]" -NoNewline -ForegroundColor Blue
    Write-Host " $status" -ForegroundColor $statusColor
}

function Write-ConfigurationOutput {
    param (
        [Parameter(Mandatory = $true)]
        [object]
        $consoleOutput,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Test", "Apply")]
        [string]
        $mode
    )

    $consoleOutputString = if ($consoleOutput -is [String]) { $consoleOutput } else { $consoleOutput | Out-String }

    $pattern = '(Assert|Apply) :: (\w+)(?: \[(.*?)\])?(?:.*\r?\n)+?.*?(System is not in the described configuration state\.|System is in the described configuration state\.|This configuration unit was not run because an assert failed or was false\.|Configuration successfully applied\.|The configuration unit failed while attempting to apply the desired state\.|The configuration unit was not in the module as expected\.)'

    $lineMatches = [regex]::Matches($consoleOutputString, $pattern)

    # Calculate max lengths for formatting output
    $maxLengths = CalculateMaxLengths $lineMatches
    $maxTypeLength = $maxLengths.MaxTypeLength
    $maxNameLength = $maxLengths.MaxNameLength

    $isOverallSuccess = $true

    foreach ($match in $lineMatches) {
        $type = $match.Groups[$resourceTypeGroupIdentifier].Value
        $name = $match.Groups[$resourceNameGroupIdentifier].Value
        $outcome = $match.Groups[$resourceOutcomeGroupIdentifier].Value

        # Determine status based on the outcome
        $status = switch -Regex ($outcome) {
            "System is not in the described configuration state\." { "Not in the described state" }
            "System is in the described configuration state\." { "In the described state" }
            "This configuration unit was not run because an assert failed or was false\." { "Skipped due to failed assert" }
            "Configuration successfully applied\." { "Successfully applied" }
            "The configuration unit failed while attempting to apply the desired state\." { "Failed to apply" }
            "The configuration unit was not in the module as expected\." { "Unknown configuration type" }
            default { "Unknown" }
        }

        $statusColor = switch ($status) {
            "Not in the described state" { "Red" }
            "Skipped due to failed assert" { "DarkYellow" }
            "Failed to apply" { "Red" }
            "Unknown configuration type" { "Red" }
            default { "Green" }
        }

        Write-OutputLine `
            -type $type `
            -name $name `
            -status $status `
            -maxTypeLength $maxTypeLength `
            -maxNameLength $maxNameLength `
            -statusColor $statusColor

        if ($status -eq "Not in the described state" -or $status -eq "Failed to apply") {
            $isOverallSuccess = $false
        }
    }

    Write-Host "----------------------------------------------------------------------"
    if ($isOverallSuccess) {
        Write-Host "Overall: System is in the described configuration state." -ForegroundColor Green
    } else {
        Write-Host "Overall: System is not in the described configuration state." -ForegroundColor Red
    }
    Write-Host "----------------------------------------------------------------------"
}

function Write-DSCv3Output {
    param (
        [Parameter(Mandatory = $true)]
        [object]
        $consoleOutput,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Test", "Apply")]
        [string]
        $mode
    )

    $consoleOutputString = if ($consoleOutput -is [String]) { $consoleOutput } else { $consoleOutput | Out-String }
    
    Write-Host "----------------------------------------------------------------------"
    Write-Host "DSC v3 Configuration Output:" -ForegroundColor Yellow
    Write-Host "----------------------------------------------------------------------"
    
    # For DSC v3, output is typically JSON formatted
    try {
        # Try to parse as JSON for structured output
        $jsonOutput = $consoleOutputString | ConvertFrom-Json -ErrorAction Stop
        
        # Display structured results
        if ($jsonOutput.results) {
            foreach ($result in $jsonOutput.results) {
                $resourceName = $result.name ?? "Unknown"
                $resourceType = $result.type ?? "Unknown"
                
                if ($result.result) {
                    $beforeState = $result.result.beforeState ?? @{}
                    $afterState = $result.result.afterState ?? @{}
                    $changed = $result.result.changedProperties ?? @()
                    
                    $status = if ($changed.Count -gt 0) { "Changed" } else { "No Change Required" }
                    $color = if ($changed.Count -gt 0) { "Yellow" } else { "Green" }
                    
                    Write-Host "$resourceType" -NoNewline -ForegroundColor Yellow
                    Write-Host " [$resourceName]" -NoNewline -ForegroundColor Blue
                    Write-Host " $status" -ForegroundColor $color
                    
                    if ($changed.Count -gt 0) {
                        foreach ($change in $changed) {
                            Write-Host "  └─ Changed: $change" -ForegroundColor Gray
                        }
                    }
                } else {
                    Write-Host "$resourceType" -NoNewline -ForegroundColor Yellow
                    Write-Host " [$resourceName]" -NoNewline -ForegroundColor Blue
                    Write-Host " Processed" -ForegroundColor Green
                }
            }
        } else {
            # Fallback for non-structured output
            Write-Host $consoleOutputString -ForegroundColor White
        }
    } catch {
        # If not JSON, display as plain text
        Write-Host $consoleOutputString -ForegroundColor White
    }
    
    Write-Host "----------------------------------------------------------------------"
}

$isPowershellRunningWithAdminRights = IsPowershellRunningWithAdminRights
if(!$isPowershellRunningWithAdminRights)
{
    break
}

# Check DSC v3 availability (informational)
$isDSCv3Available = IsDSCv3Available

$isWingetVersionCorrect = IsWingetVersionCorrect
if(!$isWingetVersionCorrect)
{
    break
}

# Main script execution loop
while ($true) {
    $choice = Show-MainMenu
    if ($choice -eq 0) { break }

    if ($choice -ge 1 -and $choice -le $profileFiles.Count) {
        $selectedProfile = $profileFiles[$choice - 1]
        $profilePath = Join-Path -Path $configurationsFolderPath -ChildPath $selectedProfile

        $subChoiceLoop = $true
        while ($subChoiceLoop) {
            $subChoice = Show-SubMenu -selectedProfile $selectedProfile

            switch ($subChoice) {
                1 { Invoke-ProfileProcess -profilePath $profilePath -mode "Apply" }
                2 { Invoke-ProfileProcess -profilePath $profilePath -mode "Test" }
                3 { $subChoiceLoop = $false } # Set flag to break out of the submenu loop
                0 { exit }
                default { Write-Host "Invalid choice. Please select a valid option." }
            }
        }
    } else {
        Write-Host "Invalid choice. Please select a valid option."
    }
}
# List of available profile files in the /configurations sub-folder
$configurationsFolderPath = ".\configurations"
$profileFiles = @(Get-ChildItem -Path $configurationsFolderPath -Filter "*.dsc.yaml" | Select-Object -ExpandProperty Name)

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
    $wingetCommand = if ($mode -eq "Apply") { "configure" } else { "configure test" }

    Write-Host "$operationVerb profile: " -NoNewline -ForegroundColor Yellow
    Write-Host $($profilePath)

    $output = Invoke-Expression "winget $wingetCommand -f `"$profilePath`" --accept-configuration-agreements" 2>&1

    Write-ConfigurationOutput -consoleOutput $output -mode $mode
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
        $typeLength = $lineMatch.Groups[1].Value.Length
        $nameLength = $lineMatch.Groups[2].Value.Length

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

    # Convert console output to string if it's not already
    $consoleOutputString = if ($consoleOutput -is [String]) { $consoleOutput } else { $consoleOutput | Out-String }

    # Determine the pattern based on the mode
    $pattern = switch ($mode) {
        "Test"  { 'Apply :: (\w+) \[(.*?)\](?:.*\r?\n)+?.*?System is (not )?in the described configuration state\.' }
        "Apply" { 'Apply :: (\w+) \[(.*?)\](?:.*\r?\n)+?.*?(Configuration successfully applied\.|The configuration unit failed while attempting to apply the desired state\.)' }
    }

    # Find matches
    $lineMatches = [regex]::Matches($consoleOutputString, $pattern)

    $maxLengths = CalculateMaxLengths $lineMatches
    $maxTypeLength = $maxLengths.MaxTypeLength
    $maxNameLength = $maxLengths.MaxNameLength

    $isOverallSuccess = $true

    foreach ($match in $lineMatches) {
        $type = $match.Groups[1].Value
        $name = $match.Groups[2].Value
        $status = switch ($mode) {
            "Test"  { if ($match.Groups[3].Success) { "System is not in the described configuration state." } else { "System is in the described configuration state." } }
            "Apply" { $match.Groups[3].Value }
        }

        $statusColor = if ($mode -eq "Test" -and $match.Groups[3].Success -or $mode -eq "Apply" -and $status -ne "Configuration successfully applied.") { "Red" } else { "Green" }

        Write-OutputLine `
            $type `
            $name `
            $status `
            $maxTypeLength `
            $maxNameLength `
            $statusColor

        if ($mode -eq "Test" -and $match.Groups[3].Success -or $mode -eq "Apply" -and $status -ne "Configuration successfully applied.") {
            $isOverallSuccess = $false
        }
    }

    Write-Host "----------------------------------------------------------------------"
    if ($isOverallSuccess) {
        $overallMessage = if ($mode -eq "Test") { "System is in the described configuration state." } else { "All configurations were successfully applied." }
        Write-Host "Overall: " -NoNewline -ForegroundColor Yellow
        Write-Host $overallMessage -ForegroundColor Green
    } else {
        $overallMessage = if ($mode -eq "Test") { "System is not in the described configuration state." } else { "Some components failed to apply the desired state." }
        Write-Host "Overall: " -NoNewline -ForegroundColor Yellow
        Write-Host $overallMessage -ForegroundColor Red
    }
    Write-Host "----------------------------------------------------------------------"
}

$isPowershellRunningWithAdminRights = IsPowershellRunningWithAdminRights
if(!$isPowershellRunningWithAdminRights)
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
                0 { exit }  # Exit the script
                default { Write-Host "Invalid choice. Please select a valid option." }
            }
        }
    } else {
        Write-Host "Invalid choice. Please select a valid option."
    }
}
# DSC v2 to DSC v3 Migration Script
# This script converts traditional DSC v0.2 configurations to DSC v3 format

param(
    [string]$SourcePath = ".\configurations-dscv2-backup",
    [string]$DestinationPath = ".\configurations"
)

function Convert-DSCv2ToV3 {
    param(
        [string]$InputPath,
        [string]$OutputPath
    )
    
    Write-Host "Converting $InputPath to DSC v3 format..."
    
    # Read the original file
    $content = Get-Content $InputPath -Raw
    $lines = Get-Content $InputPath
    
    # Start building the new configuration
    $newContent = @()
    
    # Add new schema header
    $newContent += "# yaml-language-server: `$schema=https://raw.githubusercontent.com/PowerShell/DSC/main/schemas/2024/04/bundled/config/document.vscode.json"
    $newContent += "`$schema: https://aka.ms/dsc/schemas/v3/bundled/config/document.json"
    $newContent += ""
    
    # Copy comments and description
    $inHeader = $true
    foreach ($line in $lines) {
        if ($line -match "^#" -and $inHeader) {
            if ($line -match "winget configure") {
                $newContent += $line -replace "winget configure", "dsc config"
            } else {
                $newContent += $line
            }
        } elseif ($line -match "^properties:" -or $line -match "^`$schema:") {
            $inHeader = $false
            break
        } elseif ($line.Trim() -eq "" -and $inHeader) {
            $newContent += $line
        } else {
            $inHeader = $false
            break
        }
    }
    
    # Add metadata section
    $newContent += ""
    $newContent += "metadata:"
    $newContent += "  Microsoft.DSC:"
    $newContent += "    securityContext: elevated"
    $newContent += ""
    
    # Parse the YAML to extract resources (simplified approach)
    $yamlContent = $content | ConvertFrom-Yaml
    
    # Add resources section
    $newContent += "resources:"
    
    # Add Windows assertion
    $newContent += "  - name: assert-windows"
    $newContent += "    type: Microsoft.DSC/Assertion"
    $newContent += "    properties:"
    $newContent += "      `$schema: https://aka.ms/dsc/schemas/v3/bundled/config/document.json"
    $newContent += "      resources:"
    $newContent += "        - name: os"
    $newContent += "          type: Microsoft/OSInfo"
    $newContent += "          properties:"
    $newContent += "            family: Windows"
    $newContent += ""
    
    # Process resources based on type
    $hasWinGetPackages = $false
    $hasScripts = $false
    $hasWindowsDevResources = $false
    $hasVSComponents = $false
    
    if ($yamlContent.properties.resources) {
        foreach ($resource in $yamlContent.properties.resources) {
            if ($resource.resource -match "Microsoft\.WinGet\.DSC/WinGetPackage") {
                $hasWinGetPackages = $true
            } elseif ($resource.resource -match "PSDscResources/Script") {
                $hasScripts = $true
            } elseif ($resource.resource -match "Microsoft\.Windows\.Developer/") {
                $hasWindowsDevResources = $true
            } elseif ($resource.resource -match "Microsoft\.VisualStudio\.DSC/VSComponents") {
                $hasVSComponents = $true
            }
        }
    }
    
    # Add PowerShell resource group for WinGet packages and Windows Developer resources
    if ($hasWinGetPackages -or $hasWindowsDevResources -or $hasVSComponents) {
        $newContent += "  - name: Development Tools and Settings"
        $newContent += "    type: Microsoft.DSC/PowerShell"
        $newContent += "    properties:"
        $newContent += "      resources:"
        
        if ($yamlContent.properties.resources) {
            foreach ($resource in $yamlContent.properties.resources) {
                if ($resource.resource -match "Microsoft\.WinGet\.DSC/WinGetPackage" -or 
                    $resource.resource -match "Microsoft\.Windows\.Developer/" -or
                    $resource.resource -match "Microsoft\.VisualStudio\.DSC/VSComponents") {
                    
                    $newContent += "        - name: $($resource.id)"
                    $newContent += "          type: $($resource.resource)"
                    $newContent += "          properties:"
                    
                    # Convert settings to properties
                    if ($resource.settings) {
                        foreach ($setting in $resource.settings.PSObject.Properties) {
                            if ($setting.Name -eq "id" -and $resource.resource -match "WinGetPackage") {
                                $newContent += "            Id: $($setting.Value)"
                            } else {
                                $newContent += "            $($setting.Name): $($setting.Value)"
                            }
                        }
                        
                        # Add UseLatest and Ensure for WinGet packages
                        if ($resource.resource -match "WinGetPackage") {
                            $newContent += "            UseLatest: true"
                            if (-not ($resource.settings.PSObject.Properties | Where-Object {$_.Name -eq "Ensure"})) {
                                $newContent += "            Ensure: Present"
                            }
                        }
                    }
                    
                    # Convert dependencies
                    if ($resource.dependsOn) {
                        $newContent += "          dependsOn:"
                        foreach ($dep in $resource.dependsOn) {
                            $newContent += "            - `"[resourceId('Microsoft.DSC/Assertion','assert-windows')]`""
                        }
                    }
                    $newContent += ""
                }
            }
        }
        
        $newContent += "    dependsOn:"
        $newContent += "      - `"[resourceId('Microsoft.DSC/Assertion','assert-windows')]`""
        $newContent += ""
    }
    
    # Add WindowsPowerShell resource group for scripts
    if ($hasScripts) {
        if ($yamlContent.properties.resources) {
            foreach ($resource in $yamlContent.properties.resources) {
                if ($resource.resource -match "PSDscResources/Script") {
                    $newContent += "  - name: $($resource.id)"
                    $newContent += "    type: Microsoft.Windows/WindowsPowerShell"
                    $newContent += "    properties:"
                    $newContent += "      resources:"
                    $newContent += "        - name: Script to $($resource.directives.description)"
                    $newContent += "          type: PSDesiredStateConfiguration/Script"
                    $newContent += "          properties:"
                    
                    if ($resource.settings.GetScript) {
                        $newContent += "            GetScript: |"
                        $getScriptLines = $resource.settings.GetScript -split "`n"
                        foreach ($line in $getScriptLines) {
                            $newContent += "              $line"
                        }
                    }
                    
                    if ($resource.settings.TestScript) {
                        $newContent += "            TestScript: |"
                        $testScriptLines = $resource.settings.TestScript -split "`n"
                        foreach ($line in $testScriptLines) {
                            $newContent += "              $line"
                        }
                    }
                    
                    if ($resource.settings.SetScript) {
                        $newContent += "            SetScript: |"
                        $setScriptLines = $resource.settings.SetScript -split "`n"
                        foreach ($line in $setScriptLines) {
                            $newContent += "              $line"
                        }
                    }
                    
                    $newContent += "    dependsOn:"
                    $newContent += "      - `"[resourceId('Microsoft.DSC/Assertion','assert-windows')]`""
                    if ($resource.dependsOn) {
                        foreach ($dep in $resource.dependsOn) {
                            $newContent += "      - `"[resourceId('Microsoft.WinGet.DSC/WinGetPackage','$dep')]`""
                        }
                    }
                    $newContent += ""
                }
            }
        }
    }
    
    # Write the new configuration
    $newContent | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "Converted configuration saved to $OutputPath"
}

# Install powershell-yaml module if not present
if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
    Write-Host "Installing powershell-yaml module..."
    Install-Module -Name powershell-yaml -Force -Scope CurrentUser
}

Import-Module powershell-yaml

# Get all DSC configuration files
$configFiles = Get-ChildItem -Path $SourcePath -Filter "*.dsc.yaml"

Write-Host "Found $($configFiles.Count) DSC v2 configuration files to convert"

foreach ($file in $configFiles) {
    $outputPath = Join-Path $DestinationPath $file.Name
    
    # Skip if already converted
    if (Test-Path $outputPath) {
        Write-Host "Skipping $($file.Name) - already exists in destination"
        continue
    }
    
    try {
        Convert-DSCv2ToV3 -InputPath $file.FullName -OutputPath $outputPath
    } catch {
        Write-Warning "Failed to convert $($file.Name): $($_.Exception.Message)"
    }
}

Write-Host "Migration complete!"
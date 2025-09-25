# DSC v3 Migration Guide

This document outlines the migration from DSC v2 (0.2) to DSC v3 format in the ATC WinGet Configurations repository.

## Overview

All configuration files have been migrated from DSC v2 format to DSC v3 format to provide:
- **Better Performance**: Improved execution speed and resource management
- **Enhanced Error Handling**: More detailed error messages and diagnostics
- **Structured Output**: JSON-formatted results for better programmatic integration
- **Modern Schema**: Latest DSC v3 schema with improved validation

## What Changed

### Schema Updates
```yaml
# Old DSC v2
# yaml-language-server: $schema=https://aka.ms/configuration-dsc-schema/0.2

# New DSC v3
# yaml-language-server: $schema=https://raw.githubusercontent.com/PowerShell/DSC/main/schemas/2024/04/bundled/config/document.vscode.json
$schema: https://aka.ms/dsc/schemas/v3/bundled/config/document.json
```

### Structure Changes
```yaml
# Old DSC v2 Structure
properties:
  configurationVersion: 0.2.0
  resources:
    - resource: Microsoft.WinGet.DSC/WinGetPackage
      id: MyApp
      settings:
        id: MyApp.Id

# New DSC v3 Structure
metadata:
  Microsoft.DSC:
    securityContext: elevated
resources:
  - name: My Applications
    type: Microsoft.DSC/PowerShell
    properties:
      resources:
        - name: MyApp
          type: Microsoft.WinGet.DSC/WinGetPackage
          properties:
            Id: MyApp.Id
            UseLatest: true
            Ensure: Present
```

### Resource Wrapping
- **WinGet Packages**: Now wrapped in `Microsoft.DSC/PowerShell` containers
- **Script Resources**: Converted to `PSDesiredStateConfiguration/Script` within `Microsoft.Windows/WindowsPowerShell` containers
- **Windows Settings**: Grouped logically within PowerShell containers

### Dependency Syntax
```yaml
# Old DSC v2
dependsOn:
  - MyApp

# New DSC v3
dependsOn:
  - "[resourceId('Microsoft.WinGet.DSC/WinGetPackage','MyApp')]"
```

## Installation and Usage

### 1. Install DSC v3 CLI (Recommended)
```powershell
# Via Microsoft Store
ms-appinstaller://DSC

# Or download from GitHub
# https://github.com/PowerShell/DSC/releases
```

### 2. Verify Installation
```powershell
dsc --version
```

### 3. Apply Configurations

**Option A: DSC v3 CLI**
```powershell
dsc config set -f .\configurations\dotnet-configuration.dsc.yaml
```

**Option B: WinGet (Fallback)**
```powershell
winget configure .\configurations\dotnet-configuration.dsc.yaml --accept-configuration-agreements
```

**Option C: Setup Script (Auto-Detection)**
```powershell
.\setup.ps1
```

## Backward Compatibility

The migration maintains full backward compatibility:
- **WinGet Support**: All DSC v3 configurations can still be executed using WinGet
- **Automatic Detection**: The setup script automatically detects available tools
- **Graceful Fallback**: Falls back to WinGet if DSC v3 CLI is not available

## Benefits of DSC v3

### Better Error Handling
DSC v3 provides structured error messages:
```json
{
  "results": [
    {
      "name": "MyApp",
      "type": "Microsoft.WinGet.DSC/WinGetPackage",
      "result": {
        "beforeState": {},
        "afterState": {},
        "changedProperties": ["installed"]
      }
    }
  ]
}
```

### Improved Performance
- Faster configuration parsing
- Optimized resource execution
- Better dependency resolution

### Enhanced Validation
- Schema validation at design time
- Better IntelliSense support in VS Code
- Compile-time error detection

## File Structure

```
/configurations/                 # DSC v3 configurations (current)
├── *.dsc.yaml                   # All migrated configurations
├── *-vscode-extensions.json     # VS Code extension definitions
├── dotnet-tools-configuration.json  # .NET tools configuration
└── .vsconfig                    # Visual Studio workload configuration

/configurations-dscv2-backup/    # Original DSC v2 configurations (backup)
└── *.dsc.yaml                   # Original configurations preserved

/dscv3-configurations/           # Experimental DSC v3 configs (reference)
└── *.dsc.yaml                   # Early DSC v3 experiments
```

## Troubleshooting

### DSC v3 CLI Not Found
If you see "DSC v3 CLI not found":
1. Install DSC v3 CLI as described above
2. Or use WinGet fallback: `winget configure .\configurations\your-config.dsc.yaml`

### Configuration Validation Errors
If VS Code reports schema errors:
1. Ensure you have the latest YAML extension
2. Reload VS Code window
3. Check the schema URL is accessible

### Script Resource Issues
If script resources fail:
1. Check PowerShell execution policy: `Get-ExecutionPolicy`
2. Set if needed: `Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned`
3. Ensure admin privileges for system-level changes

## Migration Validation

To validate that a configuration works correctly:

1. **Test Mode**: `dsc config test -f .\configurations\your-config.dsc.yaml`
2. **Apply Mode**: `dsc config set -f .\configurations\your-config.dsc.yaml`
3. **WinGet Validation**: `winget configure .\configurations\your-config.dsc.yaml --accept-configuration-agreements`

## Support

For issues related to:
- **DSC v3 CLI**: [PowerShell/DSC GitHub Repository](https://github.com/PowerShell/DSC)
- **WinGet**: [microsoft/winget-cli GitHub Repository](https://github.com/microsoft/winget-cli)
- **This Repository**: [atc-net/atc-winget-configurations Issues](https://github.com/atc-net/atc-winget-configurations/issues)
# Atc.Winget.Configurations

Using a WinGet Configuration file, you can consolidate manual machine setup and project onboarding to a single command that is reliable and repeatable. To achieve this, WinGet utilizes:

A YAML-formatted WinGet Configuration file that lists all of the software versions, packages, tools, dependencies, and settings required to set up the desired state of the development environment on your Windows machine.
PowerShell Desired State Configuration (DSC) to automate the configuration of your Windows operating system.
Use the Windows Package Manager winget configure command or DSC v3 CLI to initiate the configuration process.

This repository contains multiple WinGet Configuration files for different profiles, enabling streamlined and reliable machine setup and project onboarding.

**🆕 DSC v3 Support**: All configurations have been migrated to DSC v3 format while maintaining backward compatibility with WinGet's built-in DSC support.

## Table of Contents

- [Atc.Winget.Configurations](#atcwingetconfigurations)
  - [Table of Contents](#table-of-contents)
  - [Efficient Winget Profile Management](#efficient-winget-profile-management)
    - [DSC v3 Migration](#dsc-v3-migration)
    - [Customization - Personalizing Your Profile](#customization---personalizing-your-profile)
    - [Applying Profiles](#applying-profiles)
    - [Use Case Scenarios](#use-case-scenarios)
      - [DotNet Azure Developer Scenario](#dotnet-azure-developer-scenario)
      - [Web Developer Scenario](#web-developer-scenario)
  - [Requirements](#requirements)
  - [How to contribute](#how-to-contribute)

## Efficient Winget Profile Management

### DSC v3 Migration

All configurations in this repository have been migrated to **DSC v3 format** for improved performance, better error handling, and enhanced functionality. The migration includes:

- **Updated Schema**: Configurations now use the DSC v3 schema (`$schema: https://aka.ms/dsc/schemas/v3/bundled/config/document.json`)
- **Enhanced Structure**: Resources are now properly grouped and organized for better dependency management
- **Improved Error Handling**: Better diagnostics and troubleshooting information
- **Backward Compatibility**: The setup script automatically detects DSC v3 availability and falls back to WinGet when needed

#### Using DSC v3 Configurations

**Option 1: Using DSC v3 CLI (Recommended)**
```powershell
# Install DSC v3 CLI first (available via Microsoft Store or GitHub releases)
dsc config set -f .\configurations\dotnet-configuration.dsc.yaml
```

**Option 2: Using WinGet (Fallback)**
```powershell
# WinGet can still process DSC v3 configurations
winget configure .\configurations\dotnet-configuration.dsc.yaml --accept-configuration-agreements
```

**Option 3: Using the Setup Script**
```powershell
# The setup script automatically detects available tools
.\setup.ps1
```

### Customization - Personalizing Your Profile

These profiles are designed to be adaptable, allowing you to customize them according to your specific needs. Whether it's modifying the list of software, adjusting settings, or adding new functionalities, you can tailor each profile to create an ideal setup for your environment.

### Applying Profiles

Execute individual profile either directly through winget or by using the accompanying helper script [`setup.ps1`](setup.ps1). This script offers the flexibility to either test or fully implement each profile as needed. Ensure to run the script as `Administrator` since several of the profiles require administrative access to apply the profiles.

For guidance on applying each script, refer to the instructions provided at the beginning of every profile.

> Note: If you encounter the following error when running the accompanying helper script [`setup.ps1`](setup.ps1)
>
>> `setup.ps1 cannot be loaded because running scripts is disabled on this system`
>
> Run the following command:
>
>> Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Unrestricted

### Use Case Scenarios

In the [`/configurations`](configurations/) directory, you will find various profiles designed for different environments. Each profile is a curated collection of configurations to streamline your setup process.

It's important to note that the subsequent sections, showcasing scenarios for DotNet Azure Developers and Web Developers, are presented as inspirational examples. They serve to illustrate how you can leverage and modify these profiles to suit your specific requirements. Think of them as templates or starting points, from which you can build and customize your own perfect development setup. The real power of these profiles lies in their flexibility and adaptability, enabling you to mix, match, and modify to match your workflow and preferences perfectly.

#### DotNet Azure Developer Scenario

For a DotNet Azure Developer, the configuration contains the essential components for a seamless development experience. This includes setting up the operating system with the [`os`](configurations/os-configuration.dsc.yaml) configuration, integrating Azure-specific tools and settings via the [`azure`](configurations/azure-configuration.dsc.yaml) profile, and tailoring the environment for DotNet development with the [`dotnet`](configurations/dotnet-configuration.dsc.yaml) configuration.

#### Web Developer Scenario

If you're a Web Developer, the configuration is crafted to cater to your specific needs. Start with the operating system setup using the [`os`](configurations/os-configuration.dsc.yaml) configuration, and then move on to apply the [`web`](configurations/web-configuration.dsc.yaml) profile, which includes a range of tools and settings optimized for web development tasks.

## Requirements

### Required
- [`WinGet`](https://github.com/microsoft/winget-cli/releases) - Windows Package Manager
- [`PowerShell`](https://github.com/PowerShell/PowerShell/releases) - PowerShell 5.1 or later

### Recommended (for DSC v3 support)
- [`DSC v3 CLI`](https://github.com/PowerShell/DSC) - For enhanced performance and better error handling
  - Available via Microsoft Store: `ms-appinstaller://DSC`
  - Or download from GitHub releases
  - Supports improved configuration validation and structured output

### Version Requirements
- **WinGet**: Version 1.7.10661 or later
- **PowerShell**: Version 5.1 or later (PowerShell 7+ recommended for DSC v3)
- **Windows**: Windows 10 version 1809 or later, Windows 11 recommended

> **Note**: The setup script will automatically detect which tools are available and use the appropriate method to apply configurations.

## How to contribute

[Contribution Guidelines](https://atc-net.github.io/introduction/about-atc#how-to-contribute)

[Coding Guidelines](https://atc-net.github.io/introduction/about-atc#coding-guidelines)

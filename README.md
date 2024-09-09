# Atc.Winget.Configurations

Using a WinGet Configuration file, you can consolidate manual machine setup and project onboarding to a single command that is reliable and repeatable. To achieve this, WinGet utilizes:

A YAML-formatted WinGet Configuration file that lists all of the software versions, packages, tools, dependencies, and settings required to set up the desired state of the development environment on your Windows machine.
PowerShell Desired State Configuration (DSC) to automate the configuration of your Windows operating system.
Use the Windows Package Manager winget configure command to initiate the configuration process.

This repository contains multiple WinGet Configuration files for different profiles, enabling streamlined and reliable machine setup and project onboarding.

## Table of Contents

- [Atc.Winget.Configurations](#atcwingetconfigurations)
  - [Table of Contents](#table-of-contents)
  - [Efficient Winget Profile Management](#efficient-winget-profile-management)
    - [Customization - Personalizing Your Profile](#customization---personalizing-your-profile)
    - [Applying Profiles](#applying-profiles)
    - [Use Case Scenarios](#use-case-scenarios)
      - [DotNet Azure Developer Scenario](#dotnet-azure-developer-scenario)
      - [Web Developer Scenario](#web-developer-scenario)
  - [Requirements](#requirements)
  - [How to contribute](#how-to-contribute)

## Efficient Winget Profile Management

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

- [`Winget`](https://github.com/microsoft/winget-cli/releases)
- [`PowerShell`](https://github.com/microsoft/winget-cli/releases)

## How to contribute

[Contribution Guidelines](https://atc-net.github.io/introduction/about-atc#how-to-contribute)

[Coding Guidelines](https://atc-net.github.io/introduction/about-atc#coding-guidelines)

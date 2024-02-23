Start-Transcript -Path "$ENV:temp\logs\VSIXInstaller_$Extension.log" | Out-Null

$vsInstallationPath = "C:\Program Files (x86)\Microsoft Visual Studio"

if(!(Get-Item -Path $vsInstallationPath).Exists)
{
    Write-Host "Visual Studio Installation Path not found"
    Stop-Transcript | Out-Null
    Exit(1)
}

# import utility function
. "$PSScriptRoot\visual-studio-extension-install.ps1"

$visualStudioExtensions = @(
  @{ DisplayName = 'Add New File'; ItemName = 'MadsKristensen.AddNewFile64'; },
  @{ DisplayName = 'Align Assignments 2022'; ItemName = 'VisualStudioPlatformTeam.AlignAssignment2022'; },
  @{ DisplayName = 'Azure IoT Edge Tools for VS 2022'; ItemName = 'vsc-iot.vs17iotedgetools'; }
  @{ DisplayName = 'Azure ServiceBus Monitor for Visual Studio 2022'; ItemName = 'TimVinkemeier.vsservicebusmonitor2022'; },
  @{ DisplayName = 'Azure Migrate application and code assessment'; ItemName = 'ms-dotnettools.appcat'; },
  @{ DisplayName = 'Bicep for Visual Studio'; ItemName = 'ms-azuretools.visualstudiobicep'; },
  @{ DisplayName = 'Bundler & Minifier 2022+'; ItemName = 'Failwyn.BundlerMinifier64'; },
  @{ DisplayName = 'Code Alignment'; ItemName = 'cpmcgrath.Codealignment'; },
  @{ DisplayName = 'CodeMaintainability 2022'; ItemName = 'ognjen-babic.CodeMaintainability2022'; },
  @{ DisplayName = 'Copy As Html 2022'; ItemName = 'VisualStudioPlatformTeam.CopyAsHtml2022'; },
  @{ DisplayName = 'Copy Nice'; ItemName = 'MadsKristensen.CopyNice'; },
  @{ DisplayName = 'Double-Click Maximize 2022'; ItemName = 'VisualStudioPlatformTeam.Double-ClickMaximize2022'; },
  @{ DisplayName = 'Editor Enhancements'; ItemName = 'MadsKristensen.EditorEnhancements'; },
  @{ DisplayName = 'Editor Guidelines'; ItemName = 'VisualStudioPlatformTeam.EditorGuidelines'; },
  @{ DisplayName = 'EF Core Power Tools'; ItemName = 'ErikEJ.EFCorePowerTools'; },
  @{ DisplayName = 'FileDiffer'; ItemName = 'MadsKristensen.FileDiffer'; },
  @{ DisplayName = 'File Icons'; ItemName = 'MadsKristensen.FileIcons'; },
  @{ DisplayName = 'Fix Mixed Tabs 2022'; ItemName = 'VisualStudioPlatformTeam.FixMixedTabs2022'; },
  @{ DisplayName = 'HTML Snippet Pack'; ItemName = 'MadsKristensen.HTMLSnippetPack'; },
  @{ DisplayName = 'Image Optimizer'; ItemName = 'MadsKristensen.ImageOptimizer64bit'; },
  @{ DisplayName = 'Image Sprites'; ItemName = 'MadsKristensen.ImageSprites64'; },
  @{ DisplayName = 'JavaScript Snippet Pack'; ItemName = 'MadsKristensen.JavaScriptSnippetPack'; },
  @{ DisplayName = 'Live Share 2022'; ItemName = 'MS-vsliveshare.vsls-vs-2022'; },
  @{ DisplayName = 'Markdown Editor v2'; ItemName = 'MadsKristensen.MarkdownEditor2'; },
  @{ DisplayName = 'Match Margin 2022'; ItemName = 'VisualStudioPlatformTeam.MatchMargin2022'; },
  @{ DisplayName = 'Microsoft Child Process Debugging Power Tool 2022'; ItemName = 'vsdbgplat.MicrosoftChildProcessDebuggingPowerTool2022'; },
  @{ DisplayName = 'Microsoft Visual Studio Installer Projects 2022 (Preview)'; ItemName = 'VisualStudioClient.MicrosoftVisualStudio2022InstallerProjects'; },
  @{ DisplayName = 'ML.NET Model Builder 2022'; ItemName = 'MLNET.ModelBuilder2022'; },
  @{ DisplayName = 'Middle Click Scroll 2022'; ItemName = 'VisualStudioPlatformTeam.MiddleClickScroll2022'; },
  @{ DisplayName = 'Open Bin Folder'; ItemName = 'coding-with-calvin.OpenBinFolder22'; },
  @{ DisplayName = 'Open Command Line'; ItemName = 'MadsKristensen.OpenCommandLine64'; },
  @{ DisplayName = 'Open in Visual Studio Code'; ItemName = 'MadsKristensen.OpeninVisualStudioCode'; },
  @{ DisplayName = 'NPM Task Runner'; ItemName = 'MadsKristensen.NpmTaskRunner64'; },
  @{ DisplayName = 'NuGetSolver'; ItemName = 'vsext.NuGetSolver'; },
  @{ DisplayName = 'Package Installer'; ItemName = 'MadsKristensen.PackageInstaller64'; },
  @{ DisplayName = 'Peek Help 2022'; ItemName = 'VisualStudioPlatformTeam.PeekHelp2022'; },
  @{ DisplayName = 'PowerShell Tools for Visual Studio 2022'; ItemName = 'AdamRDriscoll.PowerShellToolsVS2022'; },
  @{ DisplayName = 'Productivity Power Tools 2022'; ItemName = 'VisualStudioPlatformTeam.ProductivityPowerPack2022'; },
  @{ DisplayName = 'Rainbow Braces'; ItemName = 'MadsKristensen.RainbowBraces'; },
  @{ DisplayName = 'REST API Client Code Generator for VS 2022'; ItemName = 'ChristianResmaHelle.ApiClientCodeGenerator2022'; },
  @{ DisplayName = 'ResXManager'; ItemName = 'TomEnglert.ResXManager'; },
  @{ DisplayName = 'Scroll Tabs'; ItemName = 'MadsKristensen.ScrollTabs'; },
  @{ DisplayName = 'Shifter'; ItemName = 'MadsKristensen.Shifter'; },
  @{ DisplayName = 'Shrink Empty Lines 2022'; ItemName = 'VisualStudioPlatformTeam.SyntacticLineCompression2022'; },
  @{ DisplayName = 'Solution Error Visualizer 2022'; ItemName = 'VisualStudioPlatformTeam.SolutionErrorVisualizer2022'; },
  @{ DisplayName = 'Time Stamp Margin 2022'; ItemName = 'VisualStudioPlatformTeam.TimeStampMargin2022'; },
  @{ DisplayName = 'VSColorOutput64'; ItemName = 'MikeWard-AnnArbor.VSColorOutput64'; },
  @{ DisplayName = 'Web Compiler 2022+'; ItemName = 'Failwyn.WebCompiler64'; },
  @{ DisplayName = 'Webpack Task Runner'; ItemName = 'MadsKristensen.WebPackTaskRunner'; },
  @{ DisplayName = 'XAML Styler for Visual Studio 2022'; ItemName = 'TeamXavalon.XAMLStyler2022'; },
  @{ DisplayName = 'Xunit CodeSnippets'; ItemName = 'jsakamoto.xUnitCodeSnippets'; },
  @{ DisplayName = 'ZenCoding'; ItemName = 'MadsKristensen.ZenCoding'; }
)

foreach ($visualStudioExtension in $visualStudioExtensions) {
    Install-VSIXExtension `
        -itemName $visualStudioExtension.ItemName `
        -displayName $visualStudioExtension.DisplayName
}

Stop-Transcript | Out-Null
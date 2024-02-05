function Install-VSIXExtension {
  param (
    [Parameter(Mandatory = $true)]
    [string]
    $itemName,

    [Parameter(Mandatory = $true)]
    [string]
    $displayName
  )

  $ErrorActionPreference = "Stop"
  $baseHostName = "marketplace.visualstudio.com"

  $uri = "https://$($baseHostName)/items?itemName=$($itemName)"
  $vsixLocation = "$($env:Temp)\$([guid]::NewGuid()).vsix"
  $vsInstallerServicePath = "C:\Program Files (x86)\Microsoft Visual Studio\Installer\resources\app\ServiceHub\Services\Microsoft.VisualStudio.Setup.Service"

  if (-Not $vsInstallerServicePath) {
    Write-Error "Visual Studio Installer Service is missing"
    Exit 1
  }

  $html = Invoke-WebRequest -Uri $uri -UseBasicParsing -SessionVariable session
  $anchor = $html.Links |
            Where-Object { $_.class -eq 'install-button-container' } |
            Select-Object -ExpandProperty href

  if (-Not $anchor) {
    Write-Error "Could not find download anchor tag on the Visual Studio Extensions page for the extension $($displayName)"
    Exit 1
  }

  $href = "https://$($baseHostName)$($anchor)"

  Invoke-WebRequest $href -OutFile $vsixLocation -WebSession $session

  if (-Not (Test-Path $vsixLocation)) {
    Write-Error "Downloaded VSIX file could not be located for the extension $($displayName)"
    Exit 1
  }

  Write-Host "Installing $($displayName)"
  Start-Process -Filepath "$($vsInstallerServicePath)\VSIXInstaller" -ArgumentList "/q /a $($vsixLocation)" -Wait

  Remove-Item $vsixLocation
}
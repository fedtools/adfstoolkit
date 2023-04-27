#Create log folder
$LogFilePath = "C:\ADFSToolkitLab"
if (!(Test-Path $LogFilePath)) {
    New-Item $LogFilePath -ItemType Directory
}

$TranscriptLogFile = Join-Path $LogFilePath "Transcript_ADFSToolkit.txt"
Start-Transcript -Path $TranscriptLogFile

$MainLogFile = Join-Path $LogFilePath "Mainlog.txt"
Add-Content -Path $MainLogFile -Value "------------------------------------------------------"
Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): Install-ADFSToolkit.ps1 script started..."
Add-Content -Path $MainLogFile -Value "------------------------------------------------------"
Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): Running from '$PSScriptRoot'"

#Install ADFSToolkit
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
Install-Module PowerShellGet -Force

#Install-Module ADFSToolkit
#Install-Module ADFSToolkit -RequiredVersion 2.1.0-RC3 -AllowPrerelease

#Install Claims X-Ray
$authzRules = "=>issue(Type = `"http://schemas.microsoft.com/authorization/claims/permit`", Value = `"true`"); "
$issuanceRules = "@RuleName = `"Issue all claims`"`nx:[]=>issue(claim = x); "
$redirectUrl = "https://adfshelp.microsoft.com/ClaimsXray/TokenResponse"
$samlEndpoint = New-AdfsSamlEndpoint -Binding POST -Protocol SAMLAssertionConsumer -Uri $redirectUrl

While ((Get-Service adfssrv).Status -ne [System.ServiceProcess.ServiceControllerStatus]::Running) {
    Start-Sleep -Seconds 10
}
Add-ADFSRelyingPartyTrust -Name "ClaimsXray" -Identifier "urn:microsoft:adfs:claimsxray" -IssuanceAuthorizationRules $authzRules -IssuanceTransformRules $issuanceRules -WSFedEndpoint $redirectUrl -SamlEndpoint $samlEndpoint

#Remove Scheduled Task to Install ADFS Toolkit
$TaskName = "Install ADFS Toolkit"

$schedTask = Get-ScheduledTask -TaskName "ADFSToolkit Lab - $TaskName" -TaskPath "\ADFSToolkit Lab\" -ErrorAction SilentlyContinue
if (![string]::IsNullOrEmpty($schedTask)) {
    Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): Removing scheduled task: 'ADFSToolkit Lab - $TaskName'"
    $schedTask | Unregister-ScheduledTask -Confirm:$false
    Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): Done!"
}

Stop-Transcript
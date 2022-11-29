function Register-ADFSToolkitLabScheduledTask {
    param (
        $Name,
        $Description,
        $Command,
        [switch]$AtStartup,
        [datetime]$At,
        [switch]$DeployScript
    )
    
    Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): Installing Windows Feature ADFS-Federation"

    if ($DeployScript) {
        $Command = Join-Path $PSScriptRoot $Command
    }

    $stAction = New-ScheduledTaskAction -Execute 'Powershell.exe' `
        -Argument "-ExecutionPolicy Unrestricted -NoProfile -WindowStyle Hidden -Command &{$Command}"

    if ($AtStartup) {
        $stTrigger = New-ScheduledTaskTrigger -AtStartup
    }

    if (![string]::IsNullOrEmpty($At)) {
        $stTrigger = New-ScheduledTaskTrigger -At $At -Once:$false
    }

    $stSettings = New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew -ExecutionTimeLimit ([timespan]::FromMinutes(15)) 

    try {
        $Task = Register-ScheduledTask -Action $stAction -Trigger $stTrigger -TaskName "ADFSToolkit Lab - $Name" -Description $Description -RunLevel Highest -Settings $stSettings -TaskPath "\ADFSToolkit Lab\" -User "System"
    
        Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): Done!"
    }
    catch {
        Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): Error!"
        Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): $_"
    }
}

#Create log folder
$LogFilePath = "C:\ADFSToolkitLab"
if (!(Test-Path $LogFilePath)) {
    New-Item $LogFilePath -ItemType Directory
}

$TranscriptLogFile = Join-Path $LogFilePath "Transcript_ADFS.txt"
Start-Transcript -Path $TranscriptLogFile

$MainLogFile = Join-Path $LogFilePath "Mainlog.txt"
Add-Content -Path $MainLogFile -Value "------------------------------------------------------"
Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): Install-ADFS.ps1 script started..."
Add-Content -Path $MainLogFile -Value "------------------------------------------------------"
Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): Running from '$PSScriptRoot'"

#region Create certificates
$DomainName = "ADFSTkLabAD"
$DomainDNS = "adfstoolkit.local"

Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()):Creating ADFS Certificates"
try {
    #Signing Certificate
    $certSubject = "fssigning.$DomainDNS"

    $Certificate = Get-ChildItem -DnsName $certSubject -Path cert:\LocalMachine\My
    if ($Certificate -eq $null) {
        $SigningCert = New-SelfSignedCertificate -NotAfter (Get-Date).AddYears(10) -Subject $certSubject -CertStoreLocation cert:\LocalMachine\My -KeyExportPolicy Exportable -Provider "Microsoft Enhanced RSA and AES Cryptographic Provider" -KeyLength 4096 -HashAlgorithm SHA256
        Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): $certSubject - Done!"
    }
    elseif ($Certificate -is [Object[]]) {
        $SigningCert = $Certificate[0]
    }
    else {
        $SigningCert = $Certificate
    }

    #Encryption Certificate
    $certSubject = "fsencryption.$DomainDNS"

    $Certificate = Get-ChildItem -DnsName $certSubject -Path cert:\LocalMachine\My
    if ($Certificate -eq $null) {
        $EncryptionCert = New-SelfSignedCertificate -NotAfter (Get-Date).AddYears(10) -Subject $certSubject -CertStoreLocation cert:\LocalMachine\My -KeyExportPolicy Exportable -Provider "Microsoft Enhanced RSA and AES Cryptographic Provider" -KeyLength 4096 -HashAlgorithm SHA256
        Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): $certSubject - Done!"
    }
    elseif ($Certificate -is [Object[]]) {
        $EncryptionCert = $Certificate[0]
    }
    else {
        $EncryptionCert = $Certificate
    }

    
    #SSL Certificate
    $certSubject = "fs.$DomainDNS"

    $Certificate = Get-ChildItem -DnsName $certSubject -Path cert:\LocalMachine\My
    if ($Certificate -eq $null) {
        $SSLCert = New-SelfSignedCertificate -NotAfter (Get-Date).AddYears(10) -Subject $certSubject -CertStoreLocation cert:\LocalMachine\My -KeyExportPolicy Exportable -Provider "Microsoft Enhanced RSA and AES Cryptographic Provider" -KeyLength 4096 -HashAlgorithm SHA256 -DnsName @("certauth.fs.$DomainDNS", "fs.$DomainDNS")
        Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): $certSubject - Done!"
    }
    elseif ($Certificate -is [Object[]]) {
        $SSLCert = $Certificate[0]
    }
    else {
        $SSLCert = $Certificate
    }

    Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): All done!"
}
catch {
    Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): Error!"
    Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): $_"
}

#endregion

#region Create ADFS accounts
#Create ADFS Service Account
$ServiceAccountName = "ADFS_svc"
$ServiceAccountPassword = ConvertTo-SecureString ([guid]::NewGuid().Guid) -AsPlainText -Force

Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): Checking existing ADFS Service Account"
try {
    $ADFSServiceAccount = Get-ADUser $ServiceAccountName
    Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): ADFS Service Account found. Deleting it!"
    $ADFSServiceAccount | Remove-ADUser -Confirm:$false
    Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): Done!"
}
catch {

}

Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): Creating ADFS Service Account"
try {
    New-ADUser -AccountPassword $ServiceAccountPassword -Description "ADFS Service Account" -CannotChangePassword:$true -DisplayName "ADFS Service Account" -Name $ServiceAccountName -SamAccountName $ServiceAccountName -Enabled:$true -ErrorAction Stop
    $serviceAccountCredential = New-Object System.Management.Automation.PSCredential "$DomainName\$ServiceAccountName", $ServiceAccountPassword
    Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): Done!"
}
catch {
    Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): Error!"
    Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): $_"
}

#Create ADFS Install account
$InstallAccountName = "ADFS_Install"
$InstallAccountPassword = ConvertTo-SecureString ([guid]::NewGuid().Guid) -AsPlainText -Force

Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): Checking existing ADFS Installation Account"
try {
    $ADFSInstallationAccount = Get-ADUser $InstallAccountName
    Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): ADFS Installation Account found. Deleting it!"
    $ADFSInstallationAccount | Remove-ADUser -Confirm:$false
    Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): Done!"
}
catch {

}

Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()):Creating ADFS Installation Account"
try {
    New-ADUser -AccountPassword $InstallAccountPassword -Description "ADFS Installation Account" -CannotChangePassword:$true -DisplayName "ADFS Installation Account" -Name $InstallAccountName -SamAccountName $InstallAccountName -Enabled:$true -ErrorAction Stop
    Add-ADGroupMember "Domain Admins" -Members $InstallAccountName
    Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): Done!"
    $InstallCredentials = New-Object System.Management.Automation.PSCredential "$DomainName\$InstallAccountName", $InstallAccountPassword
}
catch {
    Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): Error!"
    Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): $_"
}
#endregion

#region Create Scheduled Tasks to do next installations and remove the used ones
#Remove Scheduled Task
$TaskName = "Install ADFS"
$schedTask = Get-ScheduledTask -TaskName "ADFSToolkit Lab - $TaskName" -TaskPath "\ADFSToolkit Lab\" -ErrorAction SilentlyContinue
if (![string]::IsNullOrEmpty($schedTask)) {
    Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): Removing scheduled task: 'ADFSToolkit Lab - $TaskName'"
    $schedTask | Unregister-ScheduledTask -Confirm:$false
    Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): Done!"
}

#Create Scheduled Task to Install ADFS Toolkit
$TaskName = "Install ADFS Toolkit"
$schedTask = Get-ScheduledTask -TaskName "ADFSToolkit Lab - $TaskName" -TaskPath "\ADFSToolkit Lab\" -ErrorAction SilentlyContinue
if ([string]::IsNullOrEmpty($schedTask)) {
    Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): Creating scheduled task: 'ADFSToolkit Lab - $TaskName'"
    Register-ADFSToolkitLabScheduledTask -Name $TaskName -Description "This script installes ADFS on startup" -Command "Install-ADFSToolkit.ps1" -AtStartup -DeployScript
    Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): Done!"
}

#endregion

#Can I check if ADFS is already run?
Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): Installing AD FS Farm"
try {
    Install-AdfsFarm -CertificateThumbprint $SSLCert.Thumbprint -DecryptionCertificateThumbprint $EncryptionCert.Thumbprint -SigningCertificateThumbprint $SigningCert.Thumbprint -FederationServiceDisplayName:"ADFS Toolkit Lab Environment" -FederationServiceName:"fs.$DomainDNS" -OverwriteConfiguration:$true -ServiceAccountCredential:$serviceAccountCredential -Credential $InstallCredentials
    Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): Done!"
}
catch {
    Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): Error!"
    Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): $_"
}

Set-ADFSProperties -AutocertificateRollover $false

Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): Rebooting now!"
Stop-Transcript

Restart-Computer -Confirm:$false -Force

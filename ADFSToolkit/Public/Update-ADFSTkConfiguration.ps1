function Update-ADFSTkConfiguration {
    if (!(Test-Path $Global:ADFSTkPaths.mainConfigFile)) {
        #inform that we need a main config and that we will call that now
        Write-ADFSTkHost confNeedMainConfigurationMessage -Style Info
        $mainConfiguration = New-ADFSTkConfiguration
    }
    
    try {
        [xml]$mainConfiguration = Get-Content $Global:ADFSTkPaths.mainConfigFile
    }
    catch {
        Write-ADFSTkLog -Message (Get-ADFSTkLanguageText confCouldNotOpenDefaultConfig) -MajorFault
    }

    $mainConfigurationFile = Get-ChildItem $Global:ADFSTkPaths.mainConfigFile

    #First take a backup of the current file
    if (!(Test-Path $Global:ADFSTkPaths.mainBackupDir)) {
        Write-ADFSTkVerboseLog -Message (Get-ADFSTkLanguageText cFileDontExist -f $Global:ADFSTkPaths.mainBackupDir)

        New-Item -ItemType Directory -Path $Global:ADFSTkPaths.mainBackupDir | Out-Null
                
        Write-ADFSTkVerboseLog -Message (Get-ADFSTkLanguageText cCreated)
    }
                
    $backupFilename = "{0}_backup_v{3}_{1}{2}" -f $mainConfigurationFile.BaseName, (Get-Date).tostring("yyyyMMdd_HHmmss"), $mainConfigurationFile.Extension, $mainConfiguration.Configuration.ConfigVersion
    $backupFile = Join-Path $Global:ADFSTkPaths.mainBackupDir $backupFilename
    Copy-Item -Path $mainConfigurationFile -Destination $backupFile | Out-Null

    Write-ADFSTkLog (Get-ADFSTkLanguageText confOldConfBackedUpTo -f $backupFile) -ForegroundColor Green

    $startVersion = $mainConfiguration.Configuration.ConfigVersion
    ###Now lets upgrade in steps!###
                
    #v1.0 --> v1.1
    $currentVersion = '1.0'
    $newVersion = '1.1'
    if ($mainConfiguration.Configuration.ConfigVersion -eq $currentVersion) {
        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText confUpdatingADFSTkConfigFromTo -f $currentVersion, $newVersion)
                    
        Add-ADFSTkXML -XML $mainConfiguration -XPathParentNode "Configuration" -RefNodeName "OutputLanguage" -NodeName "Fticks" 
        Add-ADFSTkXML -XML $mainConfiguration -XPathParentNode "Configuration/Fticks" -NodeName "Server"
        Add-ADFSTkXML -XML $mainConfiguration -XPathParentNode "Configuration/Fticks" -NodeName "Salt"
        Add-ADFSTkXML -XML $mainConfiguration -XPathParentNode "Configuration/Fticks" -NodeName "LastRecordId"

        $mainConfiguration.Configuration.ConfigVersion = $newVersion
        $mainConfiguration.Save($mainConfigurationFile);

        if (Get-ADFSTkAnswer -Message (Get-ADFSTkLanguageText confRegisterFticks)) {
            #Register Fticks info
            $FticksServer = Read-Host  (Get-ADFSTkLanguageText fticksServerNameNeeded)
            Set-ADFSTkFticksServer -Server $FticksServer

            #Register the Scheduled Task for F-Ticks
            if (Get-ADFSTkAnswer -Message (Get-ADFSTkLanguageText confRegisterFticksScheduledTask)) {
                Register-ADFSTkFTicksScheduledTask
            }
        }
    }

    #Add any new attributes from Default Config or Default Federation Config to the Institution Config

    Write-ADFSTkLog (Get-ADFSTkLanguageText confUpdatedInstConfigDone -f "ADFS Toolkit", $startVersion, $newVersion) -EntryType Information
}
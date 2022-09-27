function Initialize-ADFSTk {
    $Global:ADFSTkPaths = Get-ADFSTKPaths
    $Global:ADFSTkCompatibleInstitutionConfigVersion = "1.4"
    $Global:ADFSTkCompatibleADFSTkConfigVersion = "1.0"
    $Global:ADFSTkCompatibleLanguageTableConfigVersion = "2.1"

    #region Create main dirs
    ADFSTk-TestAndCreateDir -Path $Global:ADFSTkPaths.mainDir               -PathName "ADFSTk install directory" #C:\ADFSToolkit
    ADFSTk-TestAndCreateDir -Path $Global:ADFSTkPaths.mainConfigDir         -PathName "Main configuration" #C:\ADFSToolkit\config
    ADFSTk-TestAndCreateDir -Path $Global:ADFSTkPaths.mainBackupDir         -PathName "Main backup" #C:\ADFSToolkit\config\backup
    ADFSTk-TestAndCreateDir -Path $Global:ADFSTkPaths.cacheDir              -PathName "Cache directory" #C:\ADFSToolkit\cache
    ADFSTk-TestAndCreateDir -Path $Global:ADFSTkPaths.institutionDir        -PathName "Institution config directory" #C:\ADFSToolkit\config\institution
    ADFSTk-TestAndCreateDir -Path $Global:ADFSTkPaths.institutionBackupDir  -PathName "Institution backup directory" #C:\ADFSToolkit\config\institution\backup
    ADFSTk-TestAndCreateDir -Path $Global:ADFSTkPaths.federationDir         -PathName "Federation config directory" #C:\ADFSToolkit\config\federation
    ADFSTk-TestAndCreateDir -Path $Global:ADFSTkPaths.federationBackupDir   -PathName "Federation backup directory" #C:\ADFSToolkit\config\federation\backup
    #endregion

    #region Check and setup Event Log
    # Set appropriate default logging via EventLog mechanisms

    $LogName = 'ADFSToolkit'
    $Source = 'Sync-ADFSTkAggregates'
    if (Verify-ADFSTkEventLogUsage -LogName $LogName -Source $Source) {
        #If we evaluated as true, the eventlog is now set up and we link the WriteADFSTklog to it
        Write-ADFSTkLog -SetEventLogName $LogName -SetEventLogSource $Source
    }
    else {
        # No Event logging is enabled, just this one to a file
        Write-ADFSTkLog (Get-ADFSTkLanguageText importEventLogMissingInSettings) -MajorFault            
    }
    #endregion
}
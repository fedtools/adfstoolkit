
function Uninstall-ADFSTkStore {
    ## EventLog
    $LogName = "ADFSToolkit"
    $LogSource = "ADFSTkStore"
    $logResult = Verify-ADFSTkEventLogUsage -LogName $LogName -Source $LogSource

    Write-ADFSTkLog -SetEventLogName $LogName -SetEventLogSource $LogSource

    ## ADFS 
    $Name = "ADFSTkStore"

    try {
        Remove-ADFSAttributeStore -TargetName $Name
        
        $dll = Join-Path "C:\Windows\adfs" "ADFSTkStore.dll"

        if (Test-Path $dll) {
            Remove-Item $dll
        }
        Write-ADFSTkLog (Get-ADFSTkLanguageText storeSuccessfullyUnInstalled)

        if (Get-ADFSTkAnswer (Get-ADFSTkLanguageText cRestartADFSServiceQuestion)) {
            Restart-Service adfssrv 
        }

        Write-ADFSTkHost cRunOnAllServers -f "Uninstall-ADFSTkStore"
    }
    catch {
        Write-ADFSTkLog $_ -MajorFault
    }
}

function Uninstall-ADFSTkStore {
    ## EventLog
    $LogName = "ADFSToolkit"
    $LogSource = "ADFSTkStore"
    $logResult = Verify-ADFSTkEventLogUsage -LogName $LogName -Source $LogSource

    Write-ADFSTkLog -SetEventLogName $LogName -SetEventLogSource $LogSource

    ## ADFS 
    $ADFSTkStoreObject = Get-ADFSTkStore -ReturnAsObject
    # $dllName = "ADFSTkStore.dll"
    # $Name = "ADFSTkStore"
    # $dllDestination = Join-Path "C:\Windows\adfs" $dllName
    
    # $ADFSTkStore = Get-AdfsAttributeStore -Name $Name
    # $ADFSTkStoreIsInstalled = ![string]::IsNullOrEmpty($ADFSTkStore)
    # $ADFSTkStoreDllIsInstalled = Test-Path $dllDestination
    
    if ($ADFSTkStoreObject.ADFSTkStoreIsInstalled -or $ADFSTkStoreObject.ADFSTkStoreDllIsInstalled) {
        try {
            if ($ADFSTkStoreObject.ADFSTkStoreIsInstalled -and $ADFSTkStoreObject.ADFSTkStore.Configuration.ContainsKey('IDPSALT')) {
                if (Get-ADFSTkAnswer (Get-ADFSTkLanguageText storeShowSaltQuestion) -DefaultYes) {    
                    Write-Host $ADFSTkStoreObject.ADFSTkStore.Configuration.IDPSALT -ForegroundColor Yellow
                }
            }

            if (Get-ADFSTkAnswer (Get-ADFSTkLanguageText cStopADFSServiceQuestion)) {
                if ($ADFSTkStoreObject.ADFSTkStoreIsInstalled) {
                    Remove-ADFSAttributeStore -TargetName $ADFSTkStoreObject.Name
                }

                if ($ADFSTkStoreObject.ADFSTkStoreDllIsInstalled) {
                    Stop-Service adfssrv
                    do
                    {
                        Start-Sleep -Seconds 4
                    } 
                    until((Get-Service adfssrv).Status -eq [System.ServiceProcess.ServiceControllerStatus]::Stopped)
                    
                    Remove-Item $ADFSTkStoreObject.dllDestination
                    Start-Service adfssrv 
                }
                
                Write-ADFSTkHost cADFSServiceStarted
            
                Write-ADFSTkLog (Get-ADFSTkLanguageText storeSuccessfullyUnInstalled)
                Write-ADFSTkHost cRunOnAllServers -f "Uninstall-ADFSTkStore"
            }
            else {
                Write-ADFSTkLog (Get-ADFSTkLanguageText cUnInstallationAborted)
            }
        }
        catch {
            Write-ADFSTkLog $_ -MajorFault
        }
    }
    else {
        Write-ADFSTkHost storeNotInstalled
    }
}
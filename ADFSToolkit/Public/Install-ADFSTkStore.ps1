function Install-ADFSTkStore {
    ## EventLog
    $LogName = "ADFSToolkit"
    $LogSource = "ADFSTkStore"
    $logResult = Verify-ADFSTkEventLogUsage -LogName $LogName -Source $LogSource

    Write-ADFSTkLog -SetEventLogName $LogName -SetEventLogSource $LogSource

    $ADFSTkStoreObject = Get-ADFSTkStore -ReturnAsObject

    # $dllName = "ADFSTkStore.dll"
    # $binPath = Join-Path $global:ADFSTkPaths.modulePath Bin
    # $dllSourceLocation = Join-Path $binPath $dllName
    # $dllDestination = Join-Path "C:\Windows\adfs" $dllName
    # $Name = "ADFSTkStore"
    
    # $ADFSTkStore = Get-AdfsAttributeStore -Name $Name
    # $ADFSTkStoreIsInstalled = ![string]::IsNullOrEmpty($ADFSTkStore)
    # $ADFSTkStoreDllSourceExists = Test-Path $dllSourceLocation
    # $ADFSTkStoreDllIsInstalled = Test-Path $dllDestination



        

    if (!$ADFSTkStoreObject.ADFSTkStoreIsInstalled) {
        if (Test-Path $ADFSTkStoreObject.dllSourceLocation) {
            ## ADFS 
            Write-ADFSTkHost storeSaltInfo

            $choices = @()
            $choices += New-Object System.Management.Automation.Host.ChoiceDescription "&Generate", ""
            $choices += New-Object System.Management.Automation.Host.ChoiceDescription "&Provide", ""
            $DefaultAnswer = 0

            $caption = Get-ADFSTkLanguageText storeIDPSalt
            $message = Get-ADFSTkLanguageText storeSaltQuestion

            $result = $Host.UI.PromptForChoice($caption, $message, [System.Management.Automation.Host.ChoiceDescription[]]($choices), $DefaultAnswer)

            switch ($result) {
                0 {
                    #Generate IDP Salt
                    $IdpSalt = New-ADFSTkSalt
                }
                1 {
                    #Provide IDP Salt
                    [string]$IdpSalt = Read-Host "Enter IdP Salt"

                    if ([string]::IsNullOrEmpty($IdpSalt)) {
                        Write-ADFSTkLog (Get-ADFSTkLanguageText storeInvalidSaltLength) -MajorFault
                    }
                }
            }

            try {
                Add-AdfsAttributeStore -Name "ADFSTkStore" -TypeQualifiedName "ADFSTk.ADFSTkStore, ADFSTkStore" -Configuration @{"IDPSALT" = $IdpSalt }

                Copy-ADFSTkDll
            }
            catch {
                Write-ADFSTkLog $_ -MajorFault
            }
        }
        else {
            Write-ADFSTkLog (Get-ADFSTkLanguageText storeDllNotFound) -MajorFault
        }
    }
    else {
        if (!(Test-Path $ADFSTkStoreObject.dllDestination) -or $ADFSTkStoreObject.SourceDllVersion -ne $ADFSTkStoreObject.InstalledDllVersion) {
            #Handle other servers
            Copy-ADFSTkDll
        }
        else {
            Write-ADFSTkHost storeAlreadyInstalled
        }
        
    }
}

function Copy-ADFSTkDll {
    if (Get-ADFSTkAnswer (Get-ADFSTkLanguageText cStopADFSServiceQuestion)) {
        Stop-Service adfssrv
        do {
            Start-Sleep -Seconds 1
        } 
        until((Get-Service adfssrv).Status -eq [System.ServiceProcess.ServiceControllerStatus]::Stopped)
        Start-Sleep -Seconds 5
        
        ## Copy binary to ADFS
        Copy-Item -Path $ADFSTkStoreObject.dllSourceLocation -Destination $ADFSTkStoreObject.dllDestination -Force
        
        Start-Service adfssrv
        
        Write-ADFSTkHost cADFSServiceStarted
        Write-ADFSTkLog (Get-ADFSTkLanguageText storeSuccessfullyInstalled)

        Write-ADFSTkHost cRunOnAllServers -f "Install-ADFSTkStore"
    }
    else {
        Write-ADFSTkLog (Get-ADFSTkLanguageText cUnInstallationAborted)
    }
}
function Install-ADFSTkStore {
    ## EventLog
    $LogName = "ADFSToolkit"
    $LogSource = "ADFSTkStore"
    $logResult = Verify-ADFSTkEventLogUsage -LogName $LogName -Source $LogSource

    Write-ADFSTkLog -SetEventLogName $LogName -SetEventLogSource $LogSource

    $binPath = Join-Path $global:ADFSTkPaths.modulePath Bin
    $dllFile = Join-Path $binPath 'ADFSTkStore.dll'

    if (Test-Path $dllFile) {
        ## Copy binary to ADFS
        Copy-Item -Path $dllFile -Destination "C:\Windows\adfs"

        if ((Get-AdfsAttributeStore -Name ADFSTkStore) -eq $null) {
            

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
                    # $characters = ""
                    # 0x30..0x39 | % { $characters += ([char]$_) }
                    # 0x41..0x5A | % { $characters += ([char]$_) }
                    # 0x61..0x7A | % { $characters += ([char]$_) }
    
                    [string]$IdpSalt = Read-Host "Enter IdP Salt"

                    if ($IdpSalt.Length -ne 16) {
                        Write-ADFSTkLog (Get-ADFSTkLanguageText storeInvalidSaltLength) -MajorFault
                    }

                    # $valid = $true
                    # foreach ($char in $IdpSalt) {
                    #     if (!$characters.Contains($char)) {
                    #         $valid = $false
                    #     }
                    # }

                    # if (!$valid) {
                    #     Write-ADFSTkLog (Get-ADFSTkLanguageText storeInvalidSaltCharacters) -MajorFault
                    # }
                }
            }

            try {
                Add-AdfsAttributeStore -Name "ADFSTkStore" -TypeQualifiedName "ADFSTk.ADFSTkStore, ADFSTkStore" -Configuration @{"IDPSALT" = $IdpSalt }
                Write-ADFSTkLog (Get-ADFSTkLanguageText storeSuccessfullyInstalled)
            }
            catch {
                Write-ADFSTkLog $_ -MajorFault
            }

        }
        else {
            Write-ADFSTkLog (Get-ADFSTkLanguageText storeSuccessfullyInstalled)
        }
        
        if (Get-ADFSTkAnswer (Get-ADFSTkLanguageText cRestartADFSServiceQuestion)) {
            Restart-Service adfssrv 
        }

        Write-ADFSTkHost cRunOnAllServers -f "Install-ADFSTkStore"
    }
    else {
        Write-ADFSTkHost storeDllNotFound
    }
}
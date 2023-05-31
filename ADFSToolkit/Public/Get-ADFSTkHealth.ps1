function Get-ADFSTkHealth {
    [CmdletBinding()]
    param (
        #The path to the institution configuration file that should be handled. If not provided all institution config files present in ADFSTk config will be used.
        $ConfigFile,
        #The HealtheCheckMode states how rigorous tests should be done. Defalut is done every time Sync-ADFSTkAggregates are run.
        [ValidateSet("CriticalOnly", "Default", "Full")]
        $HealthCheckMode = "Default",
        #Silent only reports true/false without output. It also tries to fix errors that can be fixed automatically.
        [switch]$Silent
    )

    $healthChecks = @{
        CheckSignature                = ($HealthCheckMode -ne "CriticalOnly") #Don't run i CriticalOnly
        CheckADFSTkConfigVersion      = $true
        CheckInstitutionConfigVersion = $true
        MFAAccesControlPolicy         = $true
        RemovedSPsStillInSPHash       = ($HealthCheckMode -eq "Full") #Only run in Full mode
        ScheduledTaskPresent          = ($HealthCheckMode -eq "Full") #Checks if the Import Metadata Scheduled Task is present
        MissingSPsInADFS              = ($HealthCheckMode -eq "Full") #Only run in Full mode
        FticsScheduledTaskPresent     = ($HealthCheckMode -eq "Full") #Checks if the F-tics Scheduled Task is present
    }

    enum Result {
        None
        Pass
        Warning
        Fail
    }

    $healthResults = @()

    #Get All paths
    if ([string]::IsNullOrEmpty($Global:ADFSTkPaths)) {
        $Global:ADFSTkPaths = Get-ADFSTKPaths
    }

    #region get config file(s)
    $ADFSTkConfig = Get-ADFSTkConfiguration

    $configFiles = @()
    if ($PSBoundParameters.ContainsKey('configFile')) {
        $configFiles += $configFile
    }
    else {
        $configFiles = $ADFSTkConfig.ConfigFiles.ConfigFile | ? enabled -eq $true | select -ExpandProperty '#text'
    }
    #endregion

    if (!$Silent) {
        $numberOfHealthChecks = ($healthChecks.Values | ? { $_ -eq $true }).Count
        $numberOfHealthChecksDone = 0
        Write-Progress -Activity "Processing Health Checks..."
    }

    #region check script signatures
    if ($healthChecks.CheckSignature) {
        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthCheckSignatureStartMessage)

        if (!$Silent) {
            $numberOfHealthChecksDone++
            Write-Progress -Activity "Processing Health Checks..." -Status "$numberOfHealthChecksDone/$numberOfHealthChecks" -CurrentOperation (Get-ADFSTkLanguageText healthCheckMissingSignaturesName) -PercentComplete ($numberOfHealthChecksDone / $numberOfHealthChecks * 100)
        }
        
        $Signatures = Get-ChildItem -Path $Global:ADFSTkPaths.modulePath -Filter *.ps1 -Recurse | Get-AuthenticodeSignature
        $validSignatures = $Signatures | ? Status -eq Valid | Select -ExpandProperty Path
        $invalidSignatures = $Signatures | ? Status -eq HashMismatch | Select -ExpandProperty Path
        $missingSignatures = $Signatures | ? Status -eq NotSigned | Select -ExpandProperty Path

        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthCheckSignatureValidSignaturesResult -f $validSignatures.Count)
        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthCheckSignatureInvalidSignaturesResult -f $invalidSignatures.Count)
        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthCheckSignatureMissingSignaturesResult -f $missingSignatures.Count)

        #Signature(s) missing...
        $resultObject = [PSCustomObject]@{
            CheckID       = "CheckSignature"
            CheckName     = Get-ADFSTkLanguageText healthCheckMissingSignaturesName
            ResultValue   = [Result]::Pass
            ResultText    = "No files with missing signatures!"
            ResultData    = @()
            ReferenceFile = ""
            FixID         = ""
        }
        if ($missingSignatures.Count -gt 0) {
            if ($Global:ADFSTkSkipNotSignedHealthCheck -eq $true) {
                $resultObject.ResultText = Get-ADFSTkLanguageText healthCheckSignatureSkipNotSignedMessage

                Write-ADFSTkVerboseLog $resultObject.ResultText

                $healthResults += $resultObject
            }
            else {
                $resultObject.ResultValue = [Result]::Fail
                $resultObject.ResultText = Get-ADFSTkLanguageText healthCheckSignatureMissingSignaturesResult -f $missingSignatures.Count
                $resultObject.ResultData = $missingSignatures
                
                Write-ADFSTkLog (Get-ADFSTkLanguageText healthCheckSignatureMissingSignaturesMessage -f ($missingSignatures | Out-String)) -EntryType Warning

                $healthResults += $resultObject
            }
        }
        else {
            $healthResults += $resultObject
        }

        #Invalid signature(s)...
        $resultObject = [PSCustomObject]@{
            CheckID       = "CheckSignature"
            CheckName     = Get-ADFSTkLanguageText healthCheckIncorectSignaturesName
            ResultValue   = [Result]::Pass
            ResultText    = "No files with incorrect signature!"
            ResultData    = @()
            ReferenceFile = ""
            FixID         = ""
        }
        if ($invalidSignatures.Count -gt 0) {
            $resultObject.ResultValue = [Result]::Fail
            $resultObject.ResultText = Get-ADFSTkLanguageText healthCheckSignatureInvalidSignaturesMessage -f ($invalidSignatures | Out-String)
            $resultObject.ResultData = $invalidSignatures

            Write-ADFSTkVerboseLog $resultObject.ResultText -EntryType Warning

            $healthResults += $resultObject
        }
        else {
            $healthResults += $resultObject
        }

        if ($resultObject.ResultValue -eq [Result]::Pass) {
            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthCheckSignaturePass)
        }
        else {
            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthCheckSignatureFail)
        }
    }
    #endregion

    #region check ADFS Toolkit config version
    if ($healthChecks.CheckADFSTkConfigVersion) {
        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthCheckADFSTkConfigVersionStartMessage)
    
        if (!$Silent) {
            $numberOfHealthChecksDone++
            Write-Progress -Activity "Processing Health Checks..." -Status "$numberOfHealthChecksDone/$numberOfHealthChecks" -CurrentOperation (Get-ADFSTkLanguageText healthCheckADFSTkConfigVersionStartMessage) -PercentComplete ($numberOfHealthChecksDone / $numberOfHealthChecks * 100)
        }
    
        $resultObject = [PSCustomObject]@{
            CheckID       = "CheckADFSTkConfigVersion"
            CheckName     = "ADFS Toolkit Configuration Version control"
            ResultValue   = [Result]::None
            ResultText    = ""
            ResultData    = @()
            ReferenceFile = ""
            FixID         = ""
        }
         
        #Check against compatible version
        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthCheckConfigVersionVerifyingVersionStart)
        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthCheckConfigVersionVerifyingVersionCompareVersions -f $ADFSTkConfig.ConfigVersion, $Global:ADFSTkCompatibleADFSTkConfigVersion)
        if ([float]$ADFSTkConfig.ConfigVersion -eq [float]$Global:ADFSTkCompatibleADFSTkConfigVersion) {
            $resultObject.ResultValue = [Result]::Pass
            $resultObject.ResultText = Get-ADFSTkLanguageText healthCheckConfigVersionVerifyingVersionSucceeded
    
            Write-ADFSTkVerboseLog $resultObject.ResultText
        }
        else {
            $resultObject.ResultValue = [Result]::Fail
            $resultObject.ResultText = Get-ADFSTkLanguageText healthIncompatibleADFSTkConfigVersion -f $ADFSTkConfig.ConfigVersion, $Global:ADFSTkCompatibleADFSTkConfigVersion
            $resultObject.FixID = "FixADFSTkConfigVersion"
    
            Write-ADFSTkLog $resultObject.ResultText -EntryType Warning
        }
        
        $healthResults += $resultObject
    
        if ($resultObject.ResultValue -eq [Result]::Pass) {
            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthCheckConfigVersionPass)
        }
        else {
            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthCheckConfigVersionFail)
        }
    }

    #endregion

    #region check institution config version
    if ($healthChecks.CheckInstitutionConfigVersion) {
        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthCheckInstitutionConfigVersionStartMessage)

        if (!$Silent) {
            $numberOfHealthChecksDone++
            Write-Progress -Activity "Processing Health Checks..." -Status "$numberOfHealthChecksDone/$numberOfHealthChecks" -CurrentOperation (Get-ADFSTkLanguageText healthCheckInstitutionConfigVersionStartMessage) -PercentComplete ($numberOfHealthChecksDone / $numberOfHealthChecks * 100)
        }

        foreach ($cf in $configFiles) {
            $resultObject = [PSCustomObject]@{
                CheckID       = "CheckInstitutionConfigVersion"
                CheckName     = "Institution Configuration Version control"
                ResultValue   = [Result]::None
                ResultText    = ""
                ResultData    = @()
                ReferenceFile = $cf
                FixID         = ""
            }
            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healhCheckConfigVersionVerifyingPath -f $cf)
            if (Test-Path $cf) {
                Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healhCheckConfigVersionVerifyingPathSucceeded)
                Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healhCheckConfigVersionVerifyingXMLParse)
                try {
                    [xml]$xmlCf = Get-Content $cf
                    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healhCheckConfigVersionVerifyingXMLParseSucceeded)

                    #Check against compatible version
                    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthCheckConfigVersionVerifyingVersionStart)
                    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthCheckConfigVersionVerifyingVersionCompareVersions -f $xmlCf.configuration.ConfigVersion, $Global:ADFSTkCompatibleInstitutionConfigVersion)
                    if ([float]$xmlCf.configuration.ConfigVersion -eq [float]$Global:ADFSTkCompatibleInstitutionConfigVersion) {
                        $resultObject.ResultValue = [Result]::Pass
                        $resultObject.ResultText = Get-ADFSTkLanguageText healthCheckConfigVersionVerifyingVersionSucceeded

                        Write-ADFSTkVerboseLog $resultObject.ResultText
                    }
                    else {
                        $resultObject.ResultValue = [Result]::Fail
                        $resultObject.ResultText = Get-ADFSTkLanguageText healthIncompatibleInstitutionConfigVersion -f $xmlCf.configuration.ConfigVersion, $Global:ADFSTkCompatibleInstitutionConfigVersion
                        $resultObject.ResultData = $xmlCf.configuration.ConfigVersion
                        $resultObject.FixID = "FixInstitutionConfigVersion"

                        Write-ADFSTkLog $resultObject.ResultText -EntryType Warning
                    }
                }
                catch {
                    $resultObject.ResultValue = [Result]::Fail
                    $resultObject.ResultText = Get-ADFSTkLanguageText healhCheckConfigVersionVerifyingXMLParseFailed -f $cf
                    $resultObject.ResultData = $cf

                    Write-ADFSTkLog $resultObject.ResultText -EntryType Warning
                }
            }
            else {
                $resultObject.ResultValue = [Result]::Fail
                $resultObject.ResultText = Get-ADFSTkLanguageText cFileDontExist -f $cf
                $resultObject.ResultData = $cf

                Write-ADFSTkLog $resultObject.ResultText  -EntryType Warning
            }
            $healthResults += $resultObject

            if ($resultObject.ResultValue -eq [Result]::Pass) {
                Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthCheckConfigVersionPass)
            }
            else {
                Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthCheckConfigVersionFail)
            }
        }
    }
    #endregion

    #region check Access Control Policy if MFA Adapter is installed
    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthCheckMFAAccessPolicyStartMessage)

    if (!$Silent) {
        $numberOfHealthChecksDone++
        Write-Progress -Activity "Processing Health Checks..." -Status "$numberOfHealthChecksDone/$numberOfHealthChecks" -CurrentOperation (Get-ADFSTkLanguageText healthCheckMFAAccessPolicyStartMessage) -PercentComplete ($numberOfHealthChecksDone / $numberOfHealthChecks * 100)
    }

    if ($healthChecks.MFAAccesControlPolicy) {
        $resultObject = [PSCustomObject]@{
            CheckID       = "MFAAccesControlPolicy"
            CheckName     = "MFA Access Control Policy"
            ResultValue   = [Result]::None
            ResultText    = ""
            ResultData    = @()
            ReferenceFile = ""
            FixID         = ""
        }

        #Only if MFA Adapter installed!
        # Check if the ADFSTK MFA Adapter is installed and add rules if so
        if ([string]::IsNullOrEmpty($Global:ADFSTKRefedsMFAUsernamePasswordAdapterInstalled)) {
            $Global:ADFSTKRefedsMFAUsernamePasswordAdapterInstalled = ![string]::IsNullOrEmpty((Get-AdfsAuthenticationProvider -Name RefedsMFAUsernamePasswordAdapter -WarningAction Ignore))
        }

        if ($Global:ADFSTKRefedsMFAUsernamePasswordAdapterInstalled) {
            if ((Get-AdfsAccessControlPolicy -Identifier ADFSToolkitPermitEveryoneAndRequireMFA) -eq $null) {
                $resultObject.ResultValue = [Result]::Fail
                $resultObject.ResultText = Get-ADFSTkLanguageText healthMFAAccesControlPolicyInstalledACPMissing
                $resultObject.FixID = "CreateACP"
            }
            else {
                $resultObject.ResultValue = [Result]::Pass
                $resultObject.ResultText = Get-ADFSTkLanguageText healthMFAAccesControlPolicyInstalledACPPresent
            }
        }
        else {
            $resultObject.ResultValue = [Result]::Pass
            $resultObject.ResultText = Get-ADFSTkLanguageText healthMFAAccesControlPolicyNotInstalled
        }

        $healthResults += $resultObject

        if ($resultObject.ResultValue -eq [Result]::Pass) {
            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthMFAAccesControlPolicyPass)
        }
        else {
            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthMFAAccesControlPolicyFail)
        }
    }
    #endregion

    #region check removedSPsStillInSPHash
    if ($healthChecks.removedSPsStillInSPHash) {
        #Automatically remove SP's from SPHash File that's not in the Metadata
        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthCheckRemovedSPsStillInSPHashSPHashStartMessage)

        if (!$Silent) {
            $numberOfHealthChecksDone++
            Write-Progress -Activity "Processing Health Checks..." -Status "$numberOfHealthChecksDone/$numberOfHealthChecks" -CurrentOperation (Get-ADFSTkLanguageText healthCheckRemovedSPsStillInSPHashSPHashStartMessage) -PercentComplete ($numberOfHealthChecksDone / $numberOfHealthChecks * 100)
        }

        foreach ($cf in $configFiles) {
            $resultObject = [PSCustomObject]@{
                CheckID       = "RemovedSPsStillInSPHash"
                CheckName     = "SP's in SPHash File not in Metadata"
                ResultValue   = [Result]::None
                ResultText    = ""
                ResultData    = @()
                ReferenceFile = $cf
                FixID         = ""
            }

            try {
                $instConfig = Get-ADFSTkInstitutionConfig -ConfigFile $cf

                $spHashFile = Join-Path $Global:ADFSTkPaths.cacheDir $instConfig.configuration.SPHashFile
                $metadataCacheFile = Join-Path $Global:ADFSTkPaths.cacheDir $instConfig.configuration.MetadataCacheFile
                if (Test-Path $spHashFile) {
                    try {
                        $fromHash = [string[]](Import-Clixml $spHashFile).Keys
                    }
                    catch {
                        #What to do?
                        #Rename it? Delete it?
                        $resultObject.Checkname = "SPHash File corrupt"
                        $resultObject.ResultValue = [Result]::Fail
                        $resultObject.ResultText = (Get-ADFSTkLanguageText healthCheckRemovedSPsStillInSPHashSPHashCorrupt -f $spHashFile)
                        $resultObject.ReferenceFile = $spHashFile
                        $resultObject.FixID = "DeleteSPHashFile"
                    }

                    if ($resultObject.ResultValue -ne [Result]::Fail) {
                        $MetadataXML = Get-ADFSTkMetadata -metadataURL $instConfig.configuration.metadataURL -CachedMetadataFile $metadataCacheFile

                        $RawAllSPs = $MetadataXML.EntitiesDescriptor.EntityDescriptor | ? { $_.SPSSODescriptor -ne $null }
                        $MetadataSPs = $RawAllSPs.EntityID

                        $compare = Compare-ADFSTkObject $MetadataSPs $fromHash -CompareType InSecondSetOnly

                        if ($compare.MembersInCompareSet -gt 0) {
                            $resultObject.ResultValue = [Result]::Warning
                            $resultObject.ResultText = (Get-ADFSTkLanguageText healthCheckRemovedSPsStillInSPHashMissingInMetadata -f $compare.MembersInCompareSet)
                            $resultObject.ReferenceFile = $spHashFile
                            $resultObject.ResultData = $compare.CompareSet
                            $resultObject.FixID = "RemoveSPsFromSPHashFile"
                        }
                        else {
                            $resultObject.ResultValue = [Result]::Pass
                            $resultObject.ResultText = Get-ADFSTkLanguageText healthCheckRemovedSPsStillInSPHashNoSPsMissingInMetadata
                        }
                    }
                }
                else {
                    $resultObject.CheckID = "SPHashMissing"
                    $resultObject.CheckName = "SP Hash File existance"
                    $resultObject.ResultValue = [Result]::Warning
                    $resultObject.ResultText = (Get-ADFSTkLanguageText healthCheckRemovedSPsStillInSPHashAllSPsWillBeImported -f $spHashFile)
                    $resultObject.ReferenceFile = $spHashFile
                }
            }
            catch {
                $resultObject.ResultValue = [Result]::Fail
                $resultObject.ResultText = $_
            }
            $healthResults += $resultObject
        }
    }
    #endregion

    #region remove/rerun missing SP's
    
    if ($healthChecks.MissingSPsInADFS) {
        #Automatically remove SP's from SPHash File that's not in the Metadata
        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthMissingSPsInADFSStartMessage)

        if (!$Silent) {
            $numberOfHealthChecksDone++
            Write-Progress -Activity "Processing Health Checks..." -Status "$numberOfHealthChecksDone/$numberOfHealthChecks" -CurrentOperation (Get-ADFSTkLanguageText healthMissingSPsInADFSStartMessage) -PercentComplete ($numberOfHealthChecksDone / $numberOfHealthChecks * 100)
        }

        foreach ($cf in $configFiles) {
            $resultObject = [PSCustomObject]@{
                CheckID       = "MissingSPsInADFS"
                CheckName     = "SP's in SPHash File missing in ADFS"
                ResultValue   = [Result]::None
                ResultText    = ""
                ResultData    = @()
                ReferenceFile = $cf
                FixID         = ""
            }

            try {
                $instConfig = Get-ADFSTkInstitutionConfig -ConfigFile $cf

                $spHashFile = Join-Path $Global:ADFSTkPaths.cacheDir $instConfig.configuration.SPHashFile
                $metadataCacheFile = Join-Path $Global:ADFSTkPaths.cacheDir $instConfig.configuration.MetadataCacheFile
                if (Test-Path $spHashFile) {
                    try {
                        $fromHash = [string[]](Import-Clixml $spHashFile).Keys
                    }
                    catch {
                        #What to do?
                        #Rename it? Delete it?
                        $resultObject.Checkname = "SPHash File corrupt"
                        $resultObject.ResultValue = [Result]::Fail
                        $resultObject.ResultText = (Get-ADFSTkLanguageText healthCheckRemovedSPsStillInSPHashSPHashCorrupt -f $spHashFile)
                        $resultObject.ReferenceFile = $spHashFile
                        $resultObject.FixID = "DeleteSPHashFile"
                    }

                    if ($resultObject.ResultValue -ne [Result]::Fail) {
                        $installed = [string[]](Get-ADFSTkToolEntityId -All | Select -ExpandProperty Identifier)
    
                        $compare = Compare-ADFSTkObject $installed $fromHash -CompareType InSecondSetOnly
    
                        if ($compare.MembersInCompareSet -gt 0) {
                            $resultObject.ResultValue = [Result]::Warning
                            $resultObject.ResultText = (Get-ADFSTkLanguageText healthMissingSPsInADFSSPsMissingInADFS -f $compare.MembersInCompareSet)
                            $resultObject.ResultData = $compare.CompareSet
                            $resultObject.ReferenceFile = $spHashFile
                            $resultObject.FixID = "AddMissingSPsInADFS"
                        }
                        else {
                            $resultObject.ResultValue = [Result]::Pass
                            $resultObject.ResultText = Get-ADFSTkLanguageText healthMissingSPsInADFSNoSPsMissingInADFS
                        }
                    }
                }
                else {
                    $resultObject.CheckID = "SPHashMissing"
                    $resultObject.CheckName = "SP Hash File existance"
                    $resultObject.ResultValue = [Result]::Warning
                    $resultObject.ResultText = (Get-ADFSTkLanguageText healthCheckRemovedSPsStillInSPHashAllSPsWillBeImported -f $spHashFile)
                    $resultObject.ReferenceFile = $spHashFile
                }
            }
            catch {
                $resultObject.ResultValue = [Result]::Fail
                $resultObject.ResultText = $_
            }
            $healthResults += $resultObject
        }
    }
    #endregion

    #region Check if the Import Metadata Scheduled Task is present
    if ($healthChecks.ScheduledTaskPresent) {
        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthScheduledTaskPresentStartMessage -f "Import Metadata")

        if (!$Silent) {
            $numberOfHealthChecksDone++
            Write-Progress -Activity "Processing Health Checks..." -Status "$numberOfHealthChecksDone/$numberOfHealthChecks" -CurrentOperation (Get-ADFSTkLanguageText healthScheduledTaskPresentStartMessage -f "Import Metadata") -PercentComplete ($numberOfHealthChecksDone / $numberOfHealthChecks * 100)
        }

        $resultObject = [PSCustomObject]@{
            CheckID       = "ScheduledTaskPresent"
            CheckName     = "Import Metadata Scheduled Task present"
            ResultValue   = [Result]::None
            ResultText    = ""
            ResultData    = @()
            ReferenceFile = ""
            FixID         = ""
        }
        
        $schedTask = Get-ScheduledTask -TaskName (Get-ADFSTkLanguageText confImportMetadata) -TaskPath "\ADFSToolkit\" -ErrorAction SilentlyContinue

        if (![string]::IsNullOrEmpty($schedTask)) {
            $resultObject.ResultValue = [Result]::Pass
            $resultObject.ResultText = Get-ADFSTkLanguageText healthScheduledTaskPresentScheduledTaskPresent -f "Import Metadata"
        }
        else {
            $resultObject.ResultValue = [Result]::Warning
            $resultObject.ResultText = Get-ADFSTkLanguageText healthScheduledTaskPresentScheduledTaskNotPresent -f "Import Metadata"
            $resultObject.FixID = "RegisterScheduledTask"
        }
        $healthResults += $resultObject
    }
    #endregion

    #region Check if F-Tics Scheduled Task is present
    if ($healthChecks.FticsScheduledTaskPresent) {
        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthScheduledTaskPresentStartMessage -f "F-Tics")

        if (!$Silent) {
            $numberOfHealthChecksDone++
            Write-Progress -Activity "Processing Health Checks..." -Status "$numberOfHealthChecksDone/$numberOfHealthChecks" -CurrentOperation (Get-ADFSTkLanguageText healthScheduledTaskPresentStartMessage -f "F-Tics") -PercentComplete ($numberOfHealthChecksDone / $numberOfHealthChecks * 100)
        }

        $resultObject = [PSCustomObject]@{
            CheckID       = "FticsScheduledTaskPresent"
            CheckName     = "F-Tics Scheduled Task present"
            ResultValue   = [Result]::None
            ResultText    = ""
            ResultData    = @()
            ReferenceFile = ""
            FixID         = ""
        }

        $schedTask = Get-ScheduledTask -TaskName (Get-ADFSTkLanguageText confProcessLoginEvents) -TaskPath "\ADFSToolkit\" -ErrorAction SilentlyContinue

        if (![string]::IsNullOrEmpty($schedTask)) {
            $resultObject.ResultValue = [Result]::Pass
            $resultObject.ResultText = Get-ADFSTkLanguageText healthScheduledTaskPresentScheduledTaskPresent -f "F-Tics"
        }
        else {
            $resultObject.ResultValue = [Result]::Warning
            $resultObject.ResultText = Get-ADFSTkLanguageText healthScheduledTaskPresentScheduledTaskNotPresent -f "F-Tics"
            $resultObject.FixID = "RegisterFticsScheduledTask"
        }
        $healthResults += $resultObject
    }
    #endregion

    #region Show result
    if (!$Silent) {
        Write-Progress -Activity "Processing Health Checks..." -PercentComplete 100 -Completed
        $healthResults | Select CheckName, ResultValue, ResultText, ReferenceFile | sort ResultValue, CheckName, ReferenceFile | ft -AutoSize -Wrap
    }

    #endregion

    #region Correct fixable errors
    $FixedAnything = $false
    
    
     #region Fix incorrect Institution Config Version(s)
    #Only if run manually
    if (!$Silent) {
        $resultObject = $healthResults | ? FixID -eq "FixADFSTkConfigVersion"
            if (![String]::IsNullOrEmpty($resultObject)) {
                if ((Get-ADFSTkAnswer (Get-ADFSTkLanguageText healthUpdateADFSTkConfigVersion))) {
                    Update-ADFSTkConfiguration
                
                    $resultObject.ResultText = (Get-ADFSTkLanguageText healthFixed) + $resultObject.ResultText
                    $resultObject.ResultValue = [Result]::Pass 

                    $FixedAnything = $true
                }
            }
    }
    #endregion

    #region Fix incorrect Institution Config Version(s)
    #Only if run manually
    if (!$Silent) {
        $resultObjects = $healthResults | ? FixID -eq "FixInstitutionConfigVersion"
        foreach ($resultObject in $resultObjects) {
            if (![String]::IsNullOrEmpty($resultObject)) {
                if ((Get-ADFSTkAnswer (Get-ADFSTkLanguageText healthUpdateInstitutionConfigVersion -f $resultObject.ReferenceFile))) {
                    Update-ADFSTkInstitutionConfiguration -ConfigurationFile $resultObject.ReferenceFile
                
                    $resultObject.ResultText = (Get-ADFSTkLanguageText healthFixed) + $resultObject.ResultText
                    $resultObject.ResultValue = [Result]::Pass 

                    $FixedAnything = $true
                }
            }
        }
    }
    #endregion

    #region MFAAccesControlPolicy
    #createACP
    $MFAAccesControlPolicy = $healthResults | ? FixID -eq "CreateACP"
    if (![String]::IsNullOrEmpty($MFAAccesControlPolicy)) {
        if ($Silent -or (Get-ADFSTkAnswer (Get-ADFSTkLanguageText healthMFAAccesControlPolicyRegisterACP))) {
            New-ADFSTKAccessControlPolicy

            Write-ADFSTkLog "Access Control Policy 'ADFSTk:Permit everyone and force MFA' created."

            $MFAAccesControlPolicy.ResultValue = [Result]::Pass
            $MFAAccesControlPolicy.ResultText = (Get-ADFSTkLanguageText healthFixed) + $resultObject.ResultText

            $FixedAnything = $true
        }
    }
    #endregion

    #region RemovedSPsStillInSPHash
    #Do we have SP's in SP Hash file that are missing in the Metadata? They should be removed...
    $removedSPsStillInSPHash = $healthResults | ? FixID -eq "RemoveSPsFromSPHashFile"
    if (![String]::IsNullOrEmpty($removedSPsStillInSPHash)) {
        foreach ($resultObject in $removedSPsStillInSPHash) {
            if ($Silent -or (Get-ADFSTkAnswer (Get-ADFSTkLanguageText healthRemoveSPsFromSPHashFileRemoveSPsNotInMetadata -f $resultObject.ReferenceFile ))) {
                Remove-ADFSTkEntityHash -SPHashFile $resultObject.ReferenceFile -EntityIDs $resultObject.ResultData
                
                $resultObject.ResultText = (Get-ADFSTkLanguageText healthFixed) + $resultObject.ResultText
                $resultObject.ResultValue = [Result]::Pass 

                $FixedAnything = $true
            }
            else {
                #No need to fail, carry on!
            }
        }
    }

    #Do we have corrupt SP Hash files?
    $removedSPsStillInSPHash = $healthResults | ? FixID -eq 'DeleteSPHashFile'
    if (![String]::IsNullOrEmpty($removedSPsStillInSPHash)) {
        foreach ($resultObject in $removedSPsStillInSPHash) {
            if ($Silent -or (Get-ADFSTkAnswer (Get-ADFSTkLanguageText healthDeleteSPHashFileDeleteCorruptSPHashFile -f $resultObject.ReferenceFile ))) {
                Remove-Item -Path $resultObject.ReferenceFile
                
                $resultObject.ResultText = (Get-ADFSTkLanguageText healthFixed) + $resultObject.ResultText
                $resultObject.ResultValue = [Result]::Pass 

                $FixedAnything = $true
            }
            else {
                #The fail result will stand!
            }
        }
    }
    #endregion

    #region RemovedSPsStillInSPHash
    #Do we have SP's in SP Hash file that are missing in ADFS? They should be removed from SP Hash File...
    $addMissingSPs = $healthResults | ? FixID -eq "AddMissingSPsInADFS"
    if (![String]::IsNullOrEmpty($addMissingSPs)) {
        foreach ($resultObject in $addMissingSPs) {
            if ($Silent -or (Get-ADFSTkAnswer (Get-ADFSTkLanguageText healthAddMissingSPsInADFSRemoveMissingSPs -f $resultObject.ReferenceFile ))) {
                Remove-ADFSTkEntityHash -SPHashFile $resultObject.ReferenceFile -EntityIDs $resultObject.ResultData

                $resultObject.ResultText = (Get-ADFSTkLanguageText healthFixed) + $resultObject.ResultText
                $resultObject.ResultValue = [Result]::Pass 

                $FixedAnything = $true
            }
            else {
                #No need to fail, carry on!
            }
        }
    }

    #endregion
        
    #region Add Import Metadata Scheduled Task
    #Only if run manually
    if (!$Silent) {
        $resultObject = $healthResults | ? FixID -eq "RegisterScheduledTask"
        if (![String]::IsNullOrEmpty($resultObject)) {
            if ((Get-ADFSTkAnswer (Get-ADFSTkLanguageText healthRegisterScheduledTaskCreateSchedTask -f "Import Metadata"))) {
                Register-ADFSTkScheduledTask
                
                $resultObject.ResultText = (Get-ADFSTkLanguageText healthFixed) + $resultObject.ResultText
                $resultObject.ResultValue = [Result]::Pass 

                $FixedAnything = $true
            }
        }
    }
    #endregion

    #region Add F-Tics Scheduled Task
    #Only if run manually
    if (!$Silent) {
        $resultObject = $healthResults | ? FixID -eq "RegisterFticsScheduledTask"
        if (![String]::IsNullOrEmpty($resultObject)) {
            if ((Get-ADFSTkAnswer (Get-ADFSTkLanguageText healthRegisterScheduledTaskCreateSchedTask -f "F-Tics"))) {
                Register-ADFSTkFTicsScheduledTask
                
                $resultObject.ResultText = (Get-ADFSTkLanguageText healthFixed) + $resultObject.ResultText
                $resultObject.ResultValue = [Result]::Pass 

                $FixedAnything = $true
            }
        }
    }
    #endregion

    if ($FixedAnything -and -not $Silent) {
        $healthResults | Select CheckName, ResultValue, ResultText, ReferenceFile | sort ResultValue, CheckName, ReferenceFile | ft -AutoSize -Wrap
    }

    if ($Silent) {
        return !($healthResults.ResultValue.Contains([Result]::Fail))
    }
    else {
        if ($healthResults.ResultValue.Contains([Result]::Fail)) {
            Write-ADFSTkLog -Message (Get-ADFSTkLanguageText healthFailed) -EntryType Error
        }
        elseif ($healthResults.ResultValue.Contains([Result]::Warning)) {
            Write-ADFSTkLog -Message (Get-ADFSTkLanguageText healthPassedWithWarnings) -EntryType Warning
        }
        else {
            Write-ADFSTkLog -Message (Get-ADFSTkLanguageText healthPassed) -EntryType Information -ForegroundColor Green
        }
    }
    <#
.SYNOPSIS
    Use this cmdlet to check the health of your installation of ADFS Toolkit
.DESCRIPTION
    This cmdlet can check different things on the installation of ADFS Toolkit. 
    Every time Sync-ADFSTkAggregates are run a default helath check is run. If an
    error is found that the health check can fix you will be asked if you want to
    do so. If the cmdlet is run with -Silent it will automatically fix errors.
.EXAMPLE
    PS C:\> Get-ADFSTkHealth
    Does a default check which includes checking that all files in the module are 
    signed and has not been altered, that the institution configuration files has
    the correct version for the installed version of ADFS Toolkit and that the 
    MFA Access Control Policy exists (if the Refeds MFA adapter is installed).
.EXAMPLE
    PS C:\> Get-ADFSTkHealth -HealthCheckMode CriticalOnly
    This excludes the check of signatures. Run this if you have changed any files
    in the module.
.EXAMPLE
    PS C:\> Get-ADFSTkHealth -HealthCheckMode Full
    Run this after upgrade of the ADFS Toolkit. It does a full scan of the installation
    including tests of missing SP's.
#>
}
function Get-ADFSTkHealth {
    [CmdletBinding()]
    param (
        $ConfigFile,
        [ValidateSet("CriticalOnly", "Default", "Full")]
        $HealthCheckMode = "Default",
        [switch]$Silent
    )

    $healtChecks = @{
        CheckSignature          = ($HealthCheckMode -ne "CriticalOnly") #Don't run i CriticalOnly
        CheckConfigVersion      = $true
        MFAAccesControlPolicy   = $true
        RemovedSPsStillInSPHash = ($HealthCheckMode -eq "Full") #Only run in Full mode
        MissingSPsInADFS        = ($HealthCheckMode -eq "Full") #Only run in Full mode
        ScheduledTaskPresent    = ($HealthCheckMode -eq "Full") #Checks if there are a Scheduled Task with the name 'Import Federated Metadata with ADFSToolkit'
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
    $configFiles = @()
    if ($PSBoundParameters.ContainsKey('configFile')) {
        $configFiles += $configFile
    }
    else {
        $configFiles = Get-ADFSTkConfiguration -ConfigFilesOnly | ? Enabled -eq $true | select -ExpandProperty ConfigFile
    }
    #endregion

    #region check script signatures
    if ($healtChecks.CheckSignature) {
        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthCheckSignatureStartMessage)
        $Signatures = Get-ChildItem -Path $Global:ADFSTkPaths.modulePath -Filter *.ps1 -Recurse | Get-AuthenticodeSignature
        $validSignatures = $Signatures | ? Status -eq Valid | Select -ExpandProperty Path
        $invalidSignatures = $Signatures | ? Status -eq HashMismatch | Select -ExpandProperty Path
        $missingSignatures = $Signatures | ? Status -eq NotSigned | Select -ExpandProperty Path

        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthCheckSignatureValidSignaturesResult -f $validSignatures.Count)
        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthCheckSignatureInvalidSignaturesResult -f $invalidSignatures.Count)
        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthCheckSignatureMissingSignaturesResult -f $missingSignatures.Count)

        #Signature(s) missing...
        if ($missingSignatures.Count -gt 0) {
            if ($Global:ADFSTkSkipNotSignedHealthCheck -eq $true) {
                $resultObject = [PSCustomObject]@{
                    CheckID       = "CheckSignature"
                    CheckName     = "Signature check"
                    ResultValue   = [Result]::Pass
                    ResultText    = Get-ADFSTkLanguageText healthCheckSignatureSkipNotSignedMessage
                    ResultData    = @()
                    ReferenceFile = ""
                    FixID         = ""
                }

                Write-ADFSTkVerboseLog $resultObject.ResultText

                $healthResults += $resultObject
            }
            else {
                $resultObject = [PSCustomObject]@{
                    CheckID       = "CheckSignature"
                    CheckName     = "Signature check"
                    ResultValue   = [Result]::Fail
                    ResultText    = Get-ADFSTkLanguageText healthCheckSignatureMissingSignaturesResult -f $missingSignatures.Count
                    ResultData    = $missingSignatures
                    ReferenceFile = ""
                    FixID         = ""
                }

                Write-ADFSTkLog (Get-ADFSTkLanguageText healthCheckSignatureMissingSignaturesMessage -f ($missingSignatures | Out-String)) -EntryType Warning

                $healthResults += $resultObject
            }
        }

        #Invalid signature(s)...
        if ($invalidSignatures.Count -gt 0) {
            $resultObject = [PSCustomObject]@{
                CheckID       = "CheckSignature"
                CheckName     = Get-ADFSTkLanguageText healthCheckSignatureName
                ResultValue   = [Result]::Fail
                ResultText    = Get-ADFSTkLanguageText healthCheckSignatureInvalidSignaturesMessage -f ($invalidSignatures | Out-String)
                ResultData    = $invalidSignatures
                ReferenceFile = ""
                FixID         = ""
            }

            Write-ADFSTkVerboseLog $resultObject.ResultText -EntryType Warning

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

    #region check config version
    if ($healtChecks.CheckConfigVersion) {

        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthCheckConfigVersionStartMessage)

        foreach ($cf in $configFiles) {
            $resultObject = [PSCustomObject]@{
                CheckID       = "CheckConfigVersion"
                CheckName     = "Version control"
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
                    if ([float]$xmlCf.configuration.ConfigVersion -ge [float]$Global:ADFSTkCompatibleInstitutionConfigVersion) {
                        $resultObject.ResultValue = [Result]::Pass
                        $resultObject.ResultText = Get-ADFSTkLanguageText healthCheckConfigVersionVerifyingVersionSucceeded

                        Write-ADFSTkVerboseLog $resultObject.ResultText
                    }
                    else {
                        $resultObject.ResultValue = [Result]::Fail
                        $resultObject.ResultText = Get-ADFSTkLanguageText healthIncompatibleInstitutionConfigVersion -f $xmlCf.configuration.ConfigVersion, $Global:ADFSTkCompatibleInstitutionConfigVersion
                        $resultObject.ResultData = $xmlCf.configuration.ConfigVersion

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
    if ($healtChecks.MFAAccesControlPolicy) {
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
    if ($healtChecks.removedSPsStillInSPHash) {
        #Automatically remove SP's from SPHash File that's not in the Metadata

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
    
    if ($healtChecks.MissingSPsInADFS) {
        #Automatically remove SP's from SPHash File that's not in the Metadata

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

    #region Check if Scheduled Task is present
    if ($healtChecks.ScheduledTaskPresent) {
        #Automatically remove SP's from SPHash File that's not in the Metadata

        $resultObject = [PSCustomObject]@{
            CheckID       = "ScheduledTaskPresent"
            CheckName     = "Scheduled Task present"
            ResultValue   = [Result]::None
            ResultText    = ""
            ResultData    = @()
            ReferenceFile = ""
            FixID         = ""
        }

        $schedTask = Get-ScheduledTask -TaskName 'Import Federated Metadata with ADFSToolkit' -TaskPath "\ADFSToolkit\" -ErrorAction SilentlyContinue

        if (![string]::IsNullOrEmpty($schedTask)) {
            $resultObject.ResultValue = [Result]::Pass
            $resultObject.ResultText = Get-ADFSTkLanguageText healthScheduledTaskPresentScheduledTaskPresent
        }
        else {
            $resultObject.ResultValue = [Result]::Warning
            $resultObject.ResultText = Get-ADFSTkLanguageText healthScheduledTaskPresentScheduledTaskNotPresent
            $resultObject.FixID = "RegisterScheduledTask"
        }
        $healthResults += $resultObject
    }
    #endregion

    #region Show result
    if (!$Silent) {
        $healthResults | Select CheckName, ResultValue, ResultText, ReferenceFile | sort ResultValue, CheckName, ReferenceFile | ft -AutoSize -Wrap
    }

    #endregion


    #region Correct fixable errors
    $FixedAnything = $false
    
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
        
    #region Add Scheduled Task
    #Only if run manually
    if (!$Silent) {
        $addMissingSPs = $healthResults | ? FixID -eq "RegisterScheduledTask"
        if (![String]::IsNullOrEmpty($addMissingSPs)) {
            if ((Get-ADFSTkAnswer (Get-ADFSTkLanguageText healthRegisterScheduledTaskCreateSchedTask))) {
                Register-ADFSTkScheduledTask
                
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
}
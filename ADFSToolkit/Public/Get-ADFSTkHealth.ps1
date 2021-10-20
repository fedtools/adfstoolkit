function Get-ADFSTkHealth {
    [CmdletBinding()]
    param (
        $ConfigFile,
        [ValidateSet("CriticalOnly", "Default", "Full")]
        $HealthCheckMode = "Default",
        [switch]$Silent
    )

    $healtChecks = @{
        signatureCheck          = ($HealthCheckMode -ne "CriticalOnly") #Don't run i CriticalOnly
        versionCheck            = $true
        mfaAccesControlPolicy   = $true
        removedSPsStillInSPHash = ($HealthCheckMode -eq "Full") #Only run in Full mode
        scheduledTaskPresent    = ($HealthCheckMode -eq "Full") #Checks if there are a Scheduled Task with the name 'Import Federated Metadata with ADFSToolkit'
    }

    enum Result {
        None
        Pass
        Warning
        Fail
    }

    $healthResults = @()
    $finalResult = $true

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
    if ($healtChecks.signatureCheck) {
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
                    CheckID       = "signatureCheck"
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
                    CheckID       = "signatureCheck"
                    CheckName     = "Signature check"
                    ResultValue   = [Result]::Fail
                    ResultText    = "{0} signatures missing in Powershell Module files" -f $missingSignatures.Count
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
                CheckID       = "signatureCheck"
                CheckName     = "Signature check"
                ResultValue   = [Result]::Fail
                ResultText    = Get-ADFSTkLanguageText healthCheckSignatureInvalidSignaturesMessage -f ($invalidSignatures | Out-String)
                ResultData    = $invalidSignatures
                ReferenceFile = ""
                FixID         = ""
            }

            Write-ADFSTkVerboseLog $resultObject.ResultText -EntryType Warning

            $healthResults += $resultObject
        }

        # if ($resultObject.ResultValue -eq [Result]::Pass) {
        #     Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthCheckSignaturePass)
        # }
        # else {
        #     Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthCheckSignatureFail)
        #     $finalResult = $false
        # }
    }
    #endregion

    #region check config version
    if ($healtChecks.versionCheck) {

        $CompatibleConfigVersion = "1.3"

        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthCheckConfigVersionStartMessage)

        foreach ($cf in $configFiles) {
            $resultObject = [PSCustomObject]@{
                CheckID       = "versionCheck"
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
                    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthCheckConfigVersionVerifyingVersionCompareVersions -f $xmlCf.configuration.ConfigVersion, $CompatibleConfigVersion)
                    if ([float]$xmlCf.configuration.ConfigVersion -ge [float]$CompatibleConfigVersion) {
                        $resultObject.ResultValue = [Result]::Pass
                        $resultObject.ResultText = Get-ADFSTkLanguageText healthCheckConfigVersionVerifyingVersionSucceeded

                        Write-ADFSTkVerboseLog $resultObject.ResultText
                    }
                    else {
                        $resultObject.ResultValue = [Result]::Fail
                        $resultObject.ResultText = Get-ADFSTkLanguageText healthIncompatibleInstitutionConfigVersion -f $xmlCf.configuration.ConfigVersion, $CompatibleConfigVersion
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
        }

        # if ($resultObject.ResultValue -eq [Result]::Pass) {
        #     Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthCheckConfigVersionPass)
        # }
        # else {
        #     Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthCheckConfigVersionFail)
        #     $finalResult = $false
        # }


    }
    #endregion

    #region check Access Control Policy if MFA Adapter is installed
    if ($healtChecks.mfaAccesControlPolicy) {
        $resultObject = [PSCustomObject]@{
            CheckID       = "mfaAccesControlPolicy"
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
                $resultObject.ResultText = "MFA Adapter installed but Access Control Policy is missing!"
                $resultObject.FixID = "createACP"
            }
            else {
                $resultObject.ResultValue = [Result]::Pass
                $resultObject.ResultText = "MFA Adapter installed and Access Control Policy present"
            }
        }
        else {
            $resultObject.ResultValue = [Result]::Pass
            $resultObject.ResultText = "MFA Adapter not installed"
        }

        $healthResults += $resultObject
    }
    #endregion

    #region check removedSPsStillInSPHash
    if ($healtChecks.removedSPsStillInSPHash) {
        #Automatically remove SP's from SPHash File that's not in the Metadata

        foreach ($cf in $configFiles) {
            $resultObject = [PSCustomObject]@{
                CheckID       = "removedSPsStillInSPHash"
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
                if (Test-Path $spHashFile) {
                    try {
                        $fromHash = [string[]](Import-Clixml $spHashFile).Keys
                    }
                    catch {
                        #What to do?
                        #Rename it? Delete it?
                        $resultObject.Checkname = "SPHash File corrupt"
                        $resultObject.ResultValue = [Result]::Fail
                        $resultObject.ResultText = ("The SP Hash file '{0}' is corrupt!" -f $spHashFile)
                        $resultObject.ReferenceFile = $spHashFile
                        $resultObject.FixID = "deleteSPHashFile"
                    }

                    if ($resultObject.ResultValue -ne [Result]::Fail) {
                        $MetadataXML = Get-ADFSTkMetadata -metadataURL $instConfig.configuration.metadataURL -CachedMetadataFile $instConfig.configuration.MetadataCacheFile

                        $RawAllSPs = $MetadataXML.EntitiesDescriptor.EntityDescriptor | ? { $_.SPSSODescriptor -ne $null }
                        $MetadataSPs = $RawAllSPs.EntityID

                        $compare = Compare-ADFSTkObject $MetadataSPs $fromHash -CompareType InSecondSetOnly

                        if ($compare.MembersInCompareSet -gt 0) {
                            $resultObject.ResultValue = [Result]::Warning
                            $resultObject.ResultText = ("{0} SP's found in the SP Hash file that are missing in the Federation metadata" -f $compare.MembersInCompareSet)
                            $resultObject.ReferenceFile = $spHashFile
                            $resultObject.ResultData = $compare.CompareSet
                            $resultObject.FixID = "removeSPsFromSPHashFile"
                        }
                        else {
                            $resultObject.ResultValue = [Result]::Pass
                            $resultObject.ResultText = "No SP's found in the SP Hash file that are missing in the Federation metadata"
                        }
                    }
                }
                else {
                    $resultObject.CheckID = "SPHashMissing"
                    $resultObject.CheckName = "SP Hash File existance"
                    $resultObject.ResultValue = [Result]::Warning
                    $resultObject.ResultText = ("SP Hash file '{0}' missing. All SP's will be imported from the Federation metadata" -f $spHashFile)
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

    #region Show result
    if (!$Silent) {
        # if ($healthResults.Values.ResultValue.Contains([Result]::Pass)) {
        #     $PassedResultObjects = $healthResults.Values | ? { $_.ResultValue -eq ([Result]::Pass) }

        #     Write-ADFSTkHost -Text "Passed tests" -ForegroundColor Green -AddLinesOverAndUnder

        #     foreach ($resultObjects in $PassedResultObjects) {
        #         foreach ($resultObject in $resultObjects) {
        #             Write-ADFSTkHost -Text "{0} - {1}" -f $resultObject.Check, $resultObject.ResultText -ForegroundColor Green
        #         }
        #     }
        # }

        # if ($healthResults.Values.ResultValue.Contains([Result]::Warning)) {
        #     $resultObjectsWithWarning = $healthResults.Values | ? { $_.ResultValue -eq ([Result]::Warning) }

        #     Write-ADFSTkHost -Text "Tests with warnings" -ForegroundColor Yellow -AddLinesOverAndUnder

        #     foreach ($resultObjects in $resultObjectsWithWarning) {
        #         foreach ($resultObject in $resultObjects) {
        #             Write-ADFSTkHost -Text "{0} (fixable={1}) - {2}" -f $resultObject.Check, `
        #             ($resultObject.Check -eq "SP's in SPHash File not in Metadata" -or `
        #                     $resultObject.Check -eq "SPHash File corrupt" -or `
        #                     $resultObject.Check -eq "MFA Access Control Policy"), `
        #                 $resultObject.ResultText -ForegroundColor Yellow
        #         }
        #     }
        # }

        # if ($healthResults.Values.ResultValue.Contains([Result]::Fail)) {
        #     $failedResultObjects = $healthResults.Values | ? { $_.ResultValue -eq ([Result]::Fail) }

        #     Write-ADFSTkHost -Text "Tests that failed" -ForegroundColor Red -AddLinesOverAndUnder

        #     foreach ($resultObjects in $failedResultObjects) {
        #         foreach ($resultObject in $resultObjects) {
        #             Write-ADFSTkHost -Text "{0} (fixable={1}) - {2}" -f $resultObject.Check, `
        #             ($resultObject.Check -eq "SP's in SPHash File not in Metadata" -or `
        #                     $resultObject.Check -eq "SPHash File corrupt" -or `
        #                     $resultObject.Check -eq "MFA Access Control Policy"), `
        #                 $resultObject.ResultText -ForegroundColor Red
        #         }
        #     }
        # }

        $healthResults | Select CheckName, ResultValue, ResultText, ReferenceFile | sort ResultValue | ft -AutoSize -Wrap
    }

    #endregion


    #region Correct fixable errors
    $FixedAnything = $false
    #region mfaAccesControlPolicyCheck
    #createACP
    $mfaAccesControlPolicyCheck = $healthResults | ? { $_.CheckID -eq 'mfaAccesControlPolicyCheck' -and $_.ResultValue -eq [Result]::Fail }
    if (![String]::IsNullOrEmpty($mfaAccesControlPolicyCheck)) {
        if ($Silent -or (Get-ADFSTkAnswer "Do you want to create the missing Access Control Policy?")) {
            $ACPMetadata = @"
    <PolicyMetadata xmlns:i="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://schemas.datacontract.org/2012/04/ADFS">
      <RequireFreshAuthentication>false</RequireFreshAuthentication>
      <IssuanceAuthorizationRules>
        <Rule>
          <Conditions>
            <Condition i:type="SpecificClaimCondition">
              <ClaimType>http://schemas.microsoft.com/ws/2008/06/identity/claims/authenticationmethod</ClaimType>
              <Operator>Equals</Operator>
              <Values>
                <Value>https://refeds.org/profile/mfa</Value>
              </Values>
            </Condition>
            <Condition i:type="MultiFactorAuthenticationCondition">
              <Operator>IsPresent</Operator>
              <Values />
            </Condition>
          </Conditions>
        </Rule>
        <Rule>
          <Conditions>
            <Condition i:type="AlwaysCondition">
              <Operator>IsPresent</Operator>
              <Values />
            </Condition>
          </Conditions>
        </Rule>
      </IssuanceAuthorizationRules>
    </PolicyMetadata>
"@
            New-AdfsAccessControlPolicy -Name "ADFSTk:Permit everyone and force MFA" `
                -Identifier ADFSToolkitPermitEveryoneAndRequireMFA `
                -Description "Grant access to everyone and require MFA for everyone." `
                -PolicyMetadata $ACPMetadata | Out-Null

            Write-ADFSTkLog "Access Control Policy 'ADFSTk:Permit everyone and force MFA' created."

            $mfaAccesControlPolicyCheck.ResultValue = [Result]::Pass
            $mfaAccesControlPolicyCheck.ResultText = "MFA Adapter installed and Access Control Policy present"

            $FixedAnything = $true
        }
        else {
            $mfaAccesControlPolicyCheck.ResultValue = [Result]::Fail
            $mfaAccesControlPolicyCheck.ResultText = "MFA Adapter installed but Access Control Policy is missing. Cannot continue!"
            $finalResult = $false
        }
    }
    #endregion

    #region removedSPsStillInSPHash
    #Do we have SP's in SP Hash file that are missing in the Metadata? They should be removed...
    $removedSPsStillInSPHash = $healthResults | ? FixID -eq "removeSPsFromSPHashFile"
    if (![String]::IsNullOrEmpty($removedSPsStillInSPHash)) {
        foreach ($resultObject in $removedSPsStillInSPHash) {
            if ($Silent -or (Get-ADFSTkAnswer ("Do you want to remove the SP's from the SP Hash file '{0}' that doesn't exists in the Metadata?" -f $resultObject.ReferenceFile ))) {
                Remove-ADFSTkEntityHash -SPHashFile $resultObject.ReferenceFile -EntityIDs $resultObject.ResultData
                
                $resultObject.ResultText = "(Fixed)" + $resultObject.ResultText
                $resultObject.ResultValue = [Result]::Pass 

                $FixedAnything = $true
            }
            else {
                #No need to fail, carry on!
            }
        }
    }

    #Do we have corrupt SP Hash files?
    $removedSPsStillInSPHash = $healthResults | ? FixID -eq 'deleteSPHashFile'
    if (![String]::IsNullOrEmpty($removedSPsStillInSPHash)) {
        foreach ($resultObject in $removedSPsStillInSPHash) {
            if ($Silent -or (Get-ADFSTkAnswer ("Do you want to delete the corrupt SP Hash file '{0}'?" -f $resultObject.ReferenceFile ))) {
                Remove-Item -Path $resultObject.ReferenceFile
                
                $resultObject.ResultText = "(Fixed)" + $resultObject.ResultText
                $resultObject.ResultValue = [Result]::Pass 

                $FixedAnything = $true
            }
            else {
                #The fail result will stand!
            }
        }
    }
    #endregion

    #endregion

    if ($FixedAnything -and -not $Silent) {
        $healthResults | Select CheckName, ResultValue, ResultText, ReferenceFile | sort ResultValue | ft -AutoSize -Wrap
    }

    if ($Silent) {
    return !($healthResults.ResultValue.Contains([Result]::Fail))
    }
    else {
        if ($healthResults.ResultValue.Contains([Result]::Fail))
        {
            Write-ADFSTkLog -Message "ADFSTkHealth FAILED" -EntryType Error
        }
        elseif ($healthResults.ResultValue.Contains([Result]::Warning)) {
            Write-ADFSTkLog -Message "ADFSTkHealth PASSED with warnings"  -EntryType Warning
        }
        else {
            Write-ADFSTkLog -Message "ADFSTkHealth PASSED" -EntryType Information -ForegroundColor Green
        }
    }
}
function Get-ADFSTkHealth {
[cmdletbinding()]
param (
    $ConfigFile,
    [ValidateSet("CriticalOnly", "Full")]
    $HealthCheckMode = "Full" #Do a full Health Check as default
)

$healtChecks = @{
    signatureCheck = $true
    versionCheck = $true
}

if ($HealthCheckMode -eq "CriticalOnly")
{
    $healtChecks.signatureCheck = $false
}

#Get All paths
if ([string]::IsNullOrEmpty($Global:ADFSTkPaths))
{
    $Global:ADFSTkPaths = Get-ADFSTKPaths
}

$finalResult = $true

#region check script signatures
    if ($healtChecks.signatureCheck)
    {
        $signatureCheckResult = $true

        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthCheckSignatureStartMessage)
        $Signatures = Get-ChildItem -Path $Global:ADFSTkPaths.modulePath -Filter *.ps1 -Recurse | Get-AuthenticodeSignature
        $validSignatures = ($Signatures | ? Status -eq Valid).Count
        $invalidSignatures = ($Signatures | ? Status -eq HashMismatch).Count
        $missingSignatures = ($Signatures | ? Status -eq NotSigned).Count
    
        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthCheckSignatureValidSignaturesResult -f $validSignatures)
        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthCheckSignatureInvalidSignaturesResult -f $invalidSignatures)
        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthCheckSignatureMissingSignaturesResult -f $missingSignatures)

        if ($invalidSignatures -gt 0)
        {
            $signatureCheckResult = $false
            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthCheckSignatureInvalidSignaturesMessage -f ($Signatures | ? Status -eq HashMismatch | Select -ExpandProperty Path | Out-String)) -EntryType Warning
        }

        if ($missingSignatures -gt 0)
        {
            if ($Global:ADFSTkSkipNotSignedHealthCheck -eq $true)
            {
                Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthCheckSignatureSkipNotSignedMessage)
            }
            else
            {
                $signatureCheckResult = $false
                Write-ADFSTkLog (Get-ADFSTkLanguageText healthCheckSignatureMissingSignaturesMessage -f ($Signatures | ? Status -eq NotSigned | Select -ExpandProperty Path | Out-String)) -EntryType Warning
            }
        }

        if ($signatureCheckResult -eq $true)
        {
            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthCheckSignaturePass)
        }
        else
        {
            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthCheckSignatureFail)
            $finalResult = $false
        }
    }
#endregion

#region check config version
    if ($healtChecks.versionCheck)
    {
        $configVersionCheckResult = $true
        $CompatibleConfigVersion = "1.3"

        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthCheckConfigVersionStartMessage)

        $configFiles = @()
        if ($PSBoundParameters.ContainsKey('configFile'))
        {
            $configFiles += $configFile
        }
        else
        {
            $configFiles = Get-ADFSTkConfiguration -ConfigFilesOnly | ? Enabled -eq $true | select -ExpandProperty ConfigFile
        }

        foreach ($cf in $configFiles)
        {
            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healhCheckConfigVersionVerifyingPath -f $cf)
            if (Test-Path $cf)
            {
                Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healhCheckConfigVersionVerifyingPathSucceeded)
                Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healhCheckConfigVersionVerifyingXMLParse)
                try 
                {
                    [xml]$xmlCf = Get-Content $cf
                    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healhCheckConfigVersionVerifyingXMLParseSucceeded)

                    #Check against compatible version
                    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthCheckConfigVersionVerifyingVersionStart)
                    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthCheckConfigVersionVerifyingVersionCompareVersions -f $xmlCf.configuration.ConfigVersion, $CompatibleConfigVersion)
                    if ([float]$xmlCf.configuration.ConfigVersion -ge [float]$CompatibleConfigVersion)
                    {
                        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthCheckConfigVersionVerifyingVersionSucceeded)
                    }
                    else
                    {
                        $configVersionCheckResult = $false
                        Write-ADFSTkLog (Get-ADFSTkLanguageText healthIncompatibleInstitutionConfigVersion -f $xmlCf.configuration.ConfigVersion, $CompatibleConfigVersion) -EntryType Warning
                    }
                }
                catch
                {
                    $configVersionCheckResult = $false
                    Write-ADFSTkLog (Get-ADFSTkLanguageText healhCheckConfigVersionVerifyingXMLParseFailed -f $cf) -EntryType Warning
                }
            }
            else
            {
                $configVersionCheckResult = $false
                Write-ADFSTkLog (Get-ADFSTkLanguageText cFileDontExist -f $ConfigFile) -EntryType Warning
            }
        }

        if ($configVersionCheckResult -eq $true)
        {
            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthCheckConfigVersionPass)
        }
        else
        {
            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText healthCheckConfigVersionFail)
            $finalResult = $false
        }
    }
#endregion

    
    return $finalResult
}


function Install-ADFSTkMFAAdapter {
    param(
        # Parameter help description
        [Parameter(Mandatory = $true, 
            ParameterSetName = 'RefedsMFA')]
        [switch]$RefedsMFA,
        # Parameter help description
        [Parameter(Mandatory = $true, 
            ParameterSetName = 'RefedsSFA')]
        [switch]$RefedsSFA
    )

    $authProviders = Get-AdfsAuthenticationProvider
    $restart = $true
    
    if (!(Get-AdfsGlobalAuthenticationPolicy).AllowAdditionalAuthenticationAsPrimary) {
        if (Get-ADFSTkAnswer (Get-ADFSTkLanguageText mfaEnableAdditionalAuthenticationAsPrimaryQuestion) -DefaultYes) {
            Set-AdfsGlobalAuthenticationPolicy -AllowAdditionalAuthenticationAsPrimary $true -Force | Out-Null
        }
        else {
            $restart = $false
            Write-ADFSTkLog (Get-ADFSTkLanguageText mfaEnableAdditionalAuthenticationAsPrimaryNeeded) -MajorFault
        }
    }

    #region Add Access Control Policy if needed
    if ((Get-AdfsAccessControlPolicy -Identifier ADFSToolkitPermitEveryoneAndRequireMFA) -eq $null) {
        $ACPMetadata = @"
        <PolicyMetadata xmlns:i="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://schemas.datacontract.org/2012/04/ADFS">
        <RequireFreshAuthentication>false</RequireFreshAuthentication>
        <IssuanceAuthorizationRules>
        <Rule>
            <Conditions>
            <Condition i:type="MultiFactorAuthenticationCondition">
                <Operator>IsPresent</Operator>
                <Values />
            </Condition>
            </Conditions>
        </Rule>
        </IssuanceAuthorizationRules>
    </PolicyMetadata>  
"@
        New-AdfsAccessControlPolicy -Name "ADFSToolkit - Permit everyone and force MFA" `
            -Identifier ADFSToolkitPermitEveryoneAndRequireMFA `
            -Description "Grant access to everyone and require MFA for everyone." `
            -PolicyMetadata $ACPMetadata | Out-Null
    }
    #endregion

    #region GAC the Dll's
    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText mfaGettingPathForDll)
    $binPath = Join-Path $global:ADFSTkPaths.modulePath Bin
    $dllFile = Join-Path $binPath 'ADFSToolkitAdapters.dll'
    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText mfaDllFound -f $dllFile)

    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText mfaLoadingAssembly -f "System.EnterpriseSerevices") 
    [System.Reflection.Assembly]::Load("System.EnterpriseServices, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a") | Out-Null
    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText cDone)
        
    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText mfaExecutingGacInstall)
    $publish = New-Object System.EnterpriseServices.Internal.Publish
    $publish.GacInstall($dllFile)
    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText cDone)
    
    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText mfaLoadingAssembly -f "dll file")
    $fn = ([System.Reflection.Assembly]::LoadFile($dllFile)).FullName
    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText cDone)
    #endregion
    
    if ($PSCmdlet.ParameterSetName -eq 'RefedsMFA') {
        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText mfaEnteringPath -f "RefedsMFA")

        $nameMFA = "RefedsMFAUsernamePasswordAdapter"
        if ($authProviders.Name.contains($nameMFA)) {
            $restart = $false
            Write-ADFSTkLog (Get-ADFSTkLanguageText mfaAdapterAlreadyInstalled -f "RefedsMFA") -EntryType Warning
        }
        else {
            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText mfaRetrievingTypeName)
            $typeNameMFA = "ADFSTk.RefedsMFAUsernamePasswordAdapter, " + $fn.ToString() + ", processorArchitecture=MSIL"
            Write-ADFSTkVerboseLog "TypeName: $typeNameMFA"
        
            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText mfaRegisteringAuthProvider)
            Register-AdfsAuthenticationProvider -TypeName $typeNameMFA -Name $nameMFA  | Out-Null
            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText cDone)
        
            Write-ADFSTkHost cInstallationDone -Style Done
            if (Get-ADFSTkAnswer (Get-ADFSTkLanguageText mfaRegisterAuthenticationProviderQuestion -f "Forms Authentication (RefedsMFA)") -DefaultYes) {
                ##Register 
                $authPolicy = Get-AdfsGlobalAuthenticationPolicy
                Set-AdfsGlobalAuthenticationPolicy -PrimaryExtranetAuthenticationProvider ($authPolicy.PrimaryExtranetAuthenticationProvider + $nameMFA) `
                    -PrimaryIntranetAuthenticationProvider ($authPolicy.PrimaryIntranetAuthenticationProvider + $nameMFA) | Out-Null
            }
            else {
                $restart = $false
            }
        }
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'RefedsSFA') {
        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText mfaEnteringPath -f "RefedsSFA")
        $nameSFA = "RefedsSFAUsernamePasswordAdapter"

        if ($authProviders.Name.contains($nameSFA)) {
            $restart = $false
            Write-ADFSTkLog (Get-ADFSTkLanguageText mfaAdapterAlreadyInstalled -f "RefedsSFA") -EntryType Warning
        }
        else {
            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText mfaRetrievingTypeName)
            $typeNameSFA = "ADFSTk.RefedsSFAUsernamePasswordAdapter, " + $fn.ToString() + ", processorArchitecture=MSIL"
            Write-ADFSTkVerboseLog "TypeName: $typeNameMFA"

            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText mfaRegisteringAuthProvider)
            Register-AdfsAuthenticationProvider -TypeName $typeNameSFA -Name $nameSFA | Out-Null
            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText cDone)
        
            Write-ADFSTkHost cInstallationDone -Style Done
            if (Get-ADFSTkAnswer (Get-ADFSTkLanguageText mfaRegisterAuthenticationProviderQuestion -f "Forms Authentication (RefedsSFA)") -DefaultYes) {
                ##Register 
                $authPolicy = Get-AdfsGlobalAuthenticationPolicy
                Set-AdfsGlobalAuthenticationPolicy -PrimaryExtranetAuthenticationProvider ($authPolicy.PrimaryExtranetAuthenticationProvider + $nameSFA) `
                    -PrimaryIntranetAuthenticationProvider ($authPolicy.PrimaryIntranetAuthenticationProvider + $nameSFA) | Out-Null
            }
            else {
                $restart = $false
            }
        }
    }

    if ($restart -and (Get-ADFSTkAnswer (Get-ADFSTkLanguageText cRestartADFSServiceQuestion) -DefaultYes)) {
        net stop adfssrv
        net start adfssrv
    }
}
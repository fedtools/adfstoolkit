

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

    #region Get all locales from the toolkit
    $languageFileName = "ADFSTk_EndUserTexts_{0}.pson"
    $languagePacks = Join-Path $Global:ADFSTKPaths.modulePath "languagePacks" 

    #Get all directories that contains a language file with the right name
    $possibleLanguageDirs = Get-ChildItem $languagePacks -Directory | ? { Test-Path (Join-Path $_.FullName ($languageFileName -f $_.Name)) }

    #Filter out the directories that doesn't have a correct name
    $configFoundLanguages = @()
    foreach ($languageDirName in $possibleLanguageDirs.Name)
    {
        try {
            $configFoundLanguages += [System.Globalization.CultureInfo]::GetCultureInfo($languageDirName).Name
        }
        catch {
            #Well the language isn't supported or an incorrect culture :(
        }
    }

    # $configFoundLanguages = (Compare-ADFSTkObject -FirstSet $possibleLanguageDirs.Name `
    #         -SecondSet ([System.Globalization.CultureInfo]::GetCultures("SpecificCultures").Name) `
    #         -CompareType Intersection).CompareSet
    #endregion


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
        New-ADFSTKAccessControlPolicy
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

                # Add display names for the authentication provider for all languages
                Set-ADFSTkAdapterLanguageTexts -adapterName $nameMFA -textID 'mfaSignInWithTwoStepVerification'
                
                $Global:ADFSTKRefedsMFAUsernamePasswordAdapterInstalled = $true

                ### Remove all SP Hash Files to re-load all SP's!
                Remove-ADFSTkCache -SPHashFileForALLConfigurations -Force
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

                # Add display names for the authentication provider for all languages
                Set-ADFSTkAdapterLanguageTexts -adapterName $nameMFA -textID 'mfaSignInWithRefedsSFA'
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

# If we need end user text in more places this should be incoperated in Get-ADFSTkLanguageText
function Set-ADFSTkAdapterLanguageTexts {
    param (
        $adapterName,
        $textID,
        [switch]$WhatIf
    )

    foreach ($language in $configFoundLanguages) {
        $languagePackDir = Join-Path $languagePacks $language
        $languageFile = Join-Path $languagePackDir $languageFileName

        try {
            $languageContent = Get-Content ($languageFile -f $language) | Out-String
            $languageData = Invoke-Expression $languageContent
        
            if ($languageData.ContainsKey('mfaSignInWithTwoStepVerification')) {
                if ($PSBoundParameters.ContainsKey('WhatIf') -and $PSBoundParameters.WhatIf -eq $true) {
                    Write-Host "Whould have written '$($languageData.$textID)' to the '$adapterName' adapter in '$language'"
                }
                else {
                    Set-AdfsAuthenticationProviderWebContent -Name $adapterName -DisplayName ($languageData.$textID) -Locale $language
                }
            }
        }
        catch {
            # Not to big concern...
        }
    }
}
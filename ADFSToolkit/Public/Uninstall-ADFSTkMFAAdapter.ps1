

function Uninstall-ADFSTkMFAAdapter {
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

    $restart = $true

    $authProviders = Get-AdfsAuthenticationProvider

    $nameMFA = "RefedsMFAUsernamePasswordAdapter"
    $nameSFA = "RefedsSFAUsernamePasswordAdapter"
    
    $authPolicy = Get-AdfsGlobalAuthenticationPolicy

    if ($PSCmdlet.ParameterSetName -eq 'RefedsMFA') {

        if ($authProviders.Name.Contains($nameMFA) -eq $false) {
            $restart = $false
            Write-ADFSTkLog (Get-ADFSTkLanguageText mfaAdapterNotPresentAborting -f 'RefedsMFA') -EntryType Warning
        }
        else {
            #If not added to Get-AdfsGlobalAuthenticationPolicy -> error
            $authPolicy.PrimaryIntranetAuthenticationProvider.Remove($nameMFA) | Out-Null
            $authPolicy.PrimaryExtranetAuthenticationProvider.Remove($nameMFA) | Out-Null
            Set-AdfsGlobalAuthenticationPolicy -PrimaryExtranetAuthenticationProvider $authPolicy.PrimaryExtranetAuthenticationProvider `
                -PrimaryIntranetAuthenticationProvider $authPolicy.PrimaryIntranetAuthenticationProvider | Out-Null

            Unregister-AdfsAuthenticationProvider -Name $nameMFA -Confirm:$false
        }
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'RefedsSFA') {
        if ($authProviders.Name.Contains($nameSFA) -eq $false) {
            $restart = $false
            Write-ADFSTkLog (Get-ADFSTkLanguageText mfaAdapterNotPresentAborting -f 'RefedsSFA') -EntryType Warning
        }
        else {
            $authPolicy.PrimaryIntranetAuthenticationProvider.Remove($nameSFA) | Out-Null
            $authPolicy.PrimaryExtranetAuthenticationProvider.Remove($nameSFA) | Out-Null
            Set-AdfsGlobalAuthenticationPolicy -PrimaryExtranetAuthenticationProvider $authPolicy.PrimaryExtranetAuthenticationProvider `
                -PrimaryIntranetAuthenticationProvider $authPolicy.PrimaryIntranetAuthenticationProvider | Out-Null
        
            Unregister-AdfsAuthenticationProvider -Name $nameSFA -Confirm:$false | Out-Null
        }
    }

    if ($restart -and (Get-ADFSTkAnswer (Get-ADFSTkLanguageText cRestartADFSServiceQuestion) -DefaultYes)) {
        net stop adfssrv
        net start adfssrv
    }

    $authProviders = Get-AdfsAuthenticationProvider
    if ($authProviders.Name.Contains($nameMFA) -eq $false `
            -and $authProviders.Name.contains($nameSFA) -eq $false) {
        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText mfaExecutingGacUnInstall)
            
        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText mfaGettingPathForDll)
        
        $binPath = Join-Path $global:ADFSTkPaths.modulePath Bin
        $dllFile = Join-Path $binPath 'ADFSToolkitAdapters.dll'
        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText mfaDllFound -f $dllFile)

        Write-ADFSTkVerboseLog "Loading System.EnterpriseSerevices Assebbly..."
        [System.Reflection.Assembly]::Load("System.EnterpriseServices, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a") | Out-Null
        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText cDone)
        
        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText mfaExecutingGacRemove)
        $publish = New-Object System.EnterpriseServices.Internal.Publish
        $publish.GacRemove($dllFile)
        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText cDone)
    }
}
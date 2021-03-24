

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
            Write-ADFSTkLog "RefedsMFA Adapter not present. Aborting..." -EntryType Warning
        }
        else {
            
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
            Write-ADFSTkLog "RefedsSFA Adapter not present. Aborting..." -EntryType Warning
        }
        else {
            $authPolicy.PrimaryIntranetAuthenticationProvider.Remove($nameSFA) | Out-Null
            $authPolicy.PrimaryExtranetAuthenticationProvider.Remove($nameSFA) | Out-Null
            Set-AdfsGlobalAuthenticationPolicy -PrimaryExtranetAuthenticationProvider $authPolicy.PrimaryExtranetAuthenticationProvider `
                -PrimaryIntranetAuthenticationProvider $authPolicy.PrimaryIntranetAuthenticationProvider | Out-Null
        
            Unregister-AdfsAuthenticationProvider -Name $nameSFA -Confirm:$false | Out-Null
        }
    }

    if ($restart -and (Get-ADFSTkAnswer "The ADFS Service needs to be restarted. Do you want to do that now?" -DefaultYes)) {
        net stop adfssrv
        net start adfssrv
    }

    $authProviders = Get-AdfsAuthenticationProvider
    if ($authProviders.Name.Contains($nameMFA) -eq $false `
            -and $authProviders.Name.contains($nameSFA) -eq $false) {
        Write-ADFSTkVerboseLog "Executing GacUninstall on dll file..."
            
        Write-ADFSTkVerboseLog "Getting path for dll file..."
        $modulePath = Get-Module -ListAvailable ADFSToolkitMFA | Sort-Object Version -Descending | Select -First 1 | Select -ExpandProperty ModuleBase
        $binPath = Join-Path $modulePath Bin
        $dllFile = Join-Path $binPath 'ADFSToolkitAdapters.dll'
        Write-ADFSTkVerboseLog "Found dll file with the following path: $dllFile"

        Write-ADFSTkVerboseLog "Loading System.EnterpriseSerevices Assebbly..."
        [System.Reflection.Assembly]::Load("System.EnterpriseServices, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a") | Out-Null
        Write-ADFSTkVerboseLog "Done!"
        
        Write-ADFSTkVerboseLog "Executing GacRemove on dll file..."
        $publish = New-Object System.EnterpriseServices.Internal.Publish
        $publish.GacRemove($dllFile)
        Write-ADFSTkVerboseLog "Done!"
    }
}
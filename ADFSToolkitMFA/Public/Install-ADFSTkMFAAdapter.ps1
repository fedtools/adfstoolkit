

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
        if (Get-ADFSTkAnswer "You need to enable the Additional Authentication As Primary property on AdfsGlobalAuthenticationPolicy. Do you want ADFSToolkitMFA to do that now?" -DefaultYes) {
            Set-AdfsGlobalAuthenticationPolicy -AllowAdditionalAuthenticationAsPrimary $true -Force | Out-Null
        }
        else {
            $restart = $false
            Write-ADFSTkLog "You have to enable the Additional Authentication As Primary property on AdfsGlobalAuthenticationPolicy to continue!" -MajorFault
        }
    }

    Write-ADFSTkVerboseLog "Getting path for dll file..."
    $modulePath = Get-Module -ListAvailable ADFSToolkitMFA | Sort-Object Version -Descending | Select -First 1 | Select -ExpandProperty ModuleBase
    $binPath = Join-Path $modulePath Bin
    $dllFile = Join-Path $binPath 'ADFSToolkitAdapters.dll'
    Write-ADFSTkVerboseLog "Found dll file with the following path: $dllFile"

    Write-ADFSTkVerboseLog "Loading System.EnterpriseSerevices Assebbly..."
    [System.Reflection.Assembly]::Load("System.EnterpriseServices, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a") | Out-Null
    Write-ADFSTkVerboseLog "Done!"
        
    Write-ADFSTkVerboseLog "Executing GacInstall on dll file..."
    $publish = New-Object System.EnterpriseServices.Internal.Publish
    $publish.GacInstall($dllFile)
    Write-ADFSTkVerboseLog "Done!"
    
    Write-ADFSTkVerboseLog "Loading dll file Assembly..."
    $fn = ([System.Reflection.Assembly]::LoadFile($dllFile)).FullName
    Write-ADFSTkVerboseLog "Done!"
    
    if ($PSCmdlet.ParameterSetName -eq 'RefedsMFA') {
        Write-ADFSTkVerboseLog "Entering RefedsMFA path..."

        $nameMFA = "RefedsMFAUsernamePasswordAdapter"
        if ($authProviders.Name.contains($nameMFA)) {
            $restart = $false
            Write-ADFSTkLog "RefedsMFA Adapter already installed! Please uninstall first to continue (Uninstall-ADFSTkMFAAdapter -RefedsMFA)." -EntryType Warning
        }
        else {
            Write-ADFSTkVerboseLog "Retrieving Type Name for RefedsMFAUsernamePasswordAdapter..."
            $typeNameMFA = "ADFSTk.RefedsMFAUsernamePasswordAdapter, " + $fn.ToString() + ", processorArchitecture=MSIL"
            Write-ADFSTkVerboseLog "TypeName: $typeNameMFA"
        
            Write-ADFSTkVerboseLog "Registerings Authentication Provider..."
            Register-AdfsAuthenticationProvider -TypeName $typeNameMFA -Name $nameMFA  | Out-Null
            Write-ADFSTkVerboseLog "Done!"
        
            Write-ADFSTkHost "Installation done!" -Style Done
            if (Get-ADFSTkAnswer "Do you want to register 'Forms Authentication (RefedsMFA)' as a primary Authentication Provider?" -DefaultYes) {
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
        Write-ADFSTkVerboseLog "Entering RefedsSFA path..."
        $nameSFA = "RefedsSFAUsernamePasswordAdapter"

        if ($authProviders.Name.contains($nameSFA)) {
            $restart = $false
            Write-ADFSTkLog "RefedsSFA Adapter already installed! Please uninstall first to continue (Uninstall-ADFSTkMFAAdapter -RefedsSFA)." -EntryType Warning
        }
        else {
            Write-ADFSTkVerboseLog "Retrieving Type Name for RefedsMFAUsernamePasswordAdapter..."
            $typeNameSFA = "ADFSTk.RefedsSFAUsernamePasswordAdapter, " + $fn.ToString() + ", processorArchitecture=MSIL"
            Write-ADFSTkVerboseLog "TypeName: $typeNameMFA"

            Write-ADFSTkVerboseLog "Registerings Authentication Provider..."
            Register-AdfsAuthenticationProvider -TypeName $typeNameSFA -Name $nameSFA | Out-Null
            Write-ADFSTkVerboseLog "Done!"
        
            Write-ADFSTkHost "Installation done!" -Style Done
            if (Get-ADFSTkAnswer "Do you want to register 'Forms Authentication (RefedsSFA)' as a primary Authentication Provider?" -DefaultYes) {
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

    if ($restart -and (Get-ADFSTkAnswer "The ADFS Service needs to be restarted. Do you want to do that now?" -DefaultYes)) {
        net stop adfssrv
        net start adfssrv
    }
}
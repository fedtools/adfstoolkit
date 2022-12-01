function Get-ADFSTkStore {
    param(
        [switch]$ReturnAsObject
    )

    $dllName = "ADFSTkStore.dll"
    $Name = "ADFSTkStore"
    $dllDestination = Join-Path "C:\Windows\adfs" $dllName
    $binPath = Join-Path $global:ADFSTkPaths.modulePath Bin
    $dllSourceLocation = Join-Path $binPath $dllName

    $ADFSTkStore = Get-AdfsAttributeStore -Name $Name
    $ADFSTkStoreIsInstalled = ![string]::IsNullOrEmpty($ADFSTkStore)
    $ADFSTkStoreDllIsInstalled = Test-Path $dllDestination
    $ADFSTkStoreDllSourceExists = Test-Path $dllSourceLocation

    if ($ADFSTkStoreDllIsInstalled) {
        $InstalledDllVersion = [Reflection.Assembly]::Load([IO.File]::ReadAllBytes($dllDestination)).GetCustomAttributes("System.Reflection.AssemblyFileVersionAttribute" , $true).Version
    }

    if ($ADFSTkStoreDllSourceExists) {
        $SourceDllVersion = [Reflection.Assembly]::Load([IO.File]::ReadAllBytes($dllSourceLocation)).GetCustomAttributes("System.Reflection.AssemblyFileVersionAttribute" , $true).Version
    }

    if ($PSBoundParameters.ContainsKey("ReturnAsObject") -and $ReturnAsObject -ne $false) {
        return @{
            Name = $Name
            ADFSTkStoreIsInstalled = $ADFSTkStoreIsInstalled
            ADFSTkStoreDllIsInstalled = $ADFSTkStoreDllIsInstalled
            ADFSTkStoreDllSourceExists = $ADFSTkStoreDllSourceExists
            InstalledDllVersion = $InstalledDllVersion
            SourceDllVersion = $SourceDllVersion
            dllSourceLocation = $dllSourceLocation
            dllDestination = $dllDestination
            ADFSTkStore = $ADFSTkStore
        }
    }
    else {
        if ($ADFSTkStoreIsInstalled -and $ADFSTkStoreDllIsInstalled) {
            Write-ADFSTkHost storeIsInstalled -ForegroundColor Green
        }
        else {
            Write-ADFSTkHost storeIsNotInstalled -ForegroundColor Red
        }

        if ($ADFSTkStoreDllIsInstalled) {
            Write-ADFSTkHost storeInstalledDllVersion -f $InstalledDllVersion
        }

        if ($ADFSTkStoreDllSourceExists) {
            Write-ADFSTkHost storeSourceDllVersion -f $SourceDllVersion
        }
        else {
            Write-ADFSTkHost storeDllNotFound
        }
    }
}
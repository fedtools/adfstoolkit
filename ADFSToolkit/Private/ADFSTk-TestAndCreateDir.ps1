function ADFSTk-TestAndCreateDir
{
param (
    # The path to test (and create if not exists)
        [Parameter(Mandatory=$true,
                   Position=0)]
    $Path,
    # The name of the directory, just for output
        [Parameter(Mandatory=$false,
                   Position=1)]
    $PathName = 'The directory'
)

    $ADFSTkModule = Get-Module -ListAvailable ADFSToolkit | Sort-Object Version -Descending | Select -First 1

    if (!(Test-Path "Function:\Write-ADFSTkLog"))
    {
        . (Join-Path $ADFSTkModule.ModuleBase 'Private\Write-ADFSTkLog.ps1')
    }

    if (Test-Path $Path)
    {
        Write-ADFSTkLog "$PathName exists at $Path"        
    }
    else
    {
        New-Item -ItemType Directory -Force -Path $Path
        Write-ADFSTkLog "$PathName did not exist, creating it here: $Path"
    }
}

<#
.Synopsis
   Checks if a directory exists and if not, creates it
.DESCRIPTION
   Checks if a directory exists and if not, creates it
.EXAMPLE
   ADFSTk-TestAndCreateDir -Path 'C:\ADFSTk' -PathName 'ADFSTk install directory'
#>

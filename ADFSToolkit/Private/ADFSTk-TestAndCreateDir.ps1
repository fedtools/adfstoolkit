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

    if (Test-Path $Path)
    {
     #   Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText cPathExistsAtPath -f $PathName, $Path)
    }
    else
    {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
    #    Write-ADFSTkVerboseLog  (Get-ADFSTkLanguageText cPathNotExistCreatingHere -f $PathName, $Path)
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

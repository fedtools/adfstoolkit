    param(
	[parameter(Mandatory=$true,Position = 0)]
        [string] $InstallDirectory,
    [parameter(Mandatory=$false,Position = 1)]
        [string] $IdpSalt 
    )


    if(Test-Path $InstallDirectory)
    {
        $Name="ADFSTkToolStore"
        $dll = Join-Path $InstallDirectory "Urn.Adfstk.Application.dll"

        if(Test-Path $dll)
        {
            ## Copy binary to ADFS
            Copy-Item -Path $dll -Destination "c:\windows\adfs" 

            ## EventLog
            $LogSource = "ADFSTkTool"
            if(![System.Diagnostics.EventLog]::SourceExists("$LogSource")){
                New-EventLog -LogName "Application" -Source $LogSource
	        }
        
            ## ADFS 
            if($PSBoundParameters.ContainsKey('IdpSalt'))
            {
                Add-AdfsAttributeStore -Name $Name -TypeQualifiedName "Urn.Adfstk.Application.ADFSTkToolStore, Urn.Adfstk.Application" -Configuration @{"IDPSALT" = $IdpSalt}  
			}
            else
            {
                Add-AdfsAttributeStore -Name $Name -TypeQualifiedName "Urn.Adfstk.Application.ADFSTkToolStore, Urn.Adfstk.Application" -Configuration @{}
                Write-Host "No Idp salt provided, this has to be set in management console with key 'IDPSALT'"
			}
            Restart-Service adfssrv 
		}
        else
        {
            Write-Host "No dll found, aborting..."
		}
    }
    else
    {
        Write-Host "Path doesn´t exist, aborting..."
        #exit $LASTEXITCODE
    }
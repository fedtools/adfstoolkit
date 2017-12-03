#Get public and private function definition files.
    $Public  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1  )
    $Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 )

   # $UserManaged = @( Get-ChildItem -Path $PSScriptRoot\config\*.ps1 )

# $Public  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
 #   $Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )


#Dot source the files

Write-Verbose -Message "ADFSToolkit Public: $Public"
Write-Verbose -Message "ADFSToolkit Private: $Private"

    Foreach($import in @($Private + $Public ))
    {
        Try
        {
            Write-Verbose -Message "ADFSToolkit is Importing $($import.fullname)"
            . $import.fullname
        }
        Catch
        {
            Write-Error -Message "ADFSToolkit failed to import function $($import.fullname): $_"
        }
    }

# Here I might...
    # Read in or create an initial config file and variable
    # Export Public functions ($Public.BaseName) for WIP modules
    # Set variables visible to the module and its functions only


#Export-ModuleMember -Function $Public.Basename

Export-ModuleMember -Function  Import-FedMetadata

# uncomment to test the config tester: Export-ModuleMember -Function  Import-FedMetadata,Test-ADFSTkConfiguration


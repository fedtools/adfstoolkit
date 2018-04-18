#Get public and private function definition files.
    $Public  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1  )
    $Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 )

   $UserManaged = @( Get-ChildItem -Path $PSScriptRoot\config\*.ps1 )

#Dot source the files
Write-Verbose -Message "ADFSToolkit Public: $Public"
Write-Verbose -Message "ADFSToolkit Private: $Private"

    Foreach($import in @($Private + $Public + $UserManaged ))
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


Export-ModuleMember -Function  Import-ADFSTkMetadata,New-ADFSTkConfiguration,Unpublish-ADFSTkAggregate,Get-ADFSTkTransformRuleObjects


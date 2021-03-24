#Get public and private function definition files.
    $Public  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1  )
    $Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 )

   $UserManaged = @( Get-ChildItem -Path $PSScriptRoot\config\*.ps1 )

#Dot source the files
Write-Verbose -Message "ADFSToolkitMFA Public: $Public"
Write-Verbose -Message "ADFSToolkitMFA Private: $Private"

    Foreach($import in @($Private + $Public + $UserManaged ))
    {
        Try
        {
            Write-Verbose -Message "ADFSToolkitMFA is Importing $($import.fullname)"
            . $import.fullname
        }
        Catch
        {
            Write-Error -Message "ADFSToolkitMFA failed to import function $($import.fullname): $_"
        }
    }


Export-ModuleMember -Function  Install-ADFSTkMFAAdapter,Uninstall-ADFSTkMFAAdapter,Get-ADFSTkMFAAdapter


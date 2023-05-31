function Set-ADFSTkFticsServer {
param (
    #The DNS name of the F-Tics server
    [Parameter(Mandatory = $true)]
    $Server
)

    Set-ADFSTkConfiguration -FticsServer $Server -FticsSalt (New-ADFSTkSalt)
    Write-ADFSTkLog -Message (Get-ADFSTkLanguageText fticsServerAndSaltUpdated -f $Server) -EventID 302
}
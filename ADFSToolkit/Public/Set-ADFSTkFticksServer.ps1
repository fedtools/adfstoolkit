function Set-ADFSTkFticksServer {
param (
    #The DNS name of the F-Ticks server
    [Parameter(Mandatory = $true)]
    $Server
)

    Set-ADFSTkConfiguration -FticksServer $Server -FticksSalt (New-ADFSTkSalt)
    Write-ADFSTkLog -Message (Get-ADFSTkLanguageText fticksServerAndSaltUpdated -f $Server) -EventID 302
}
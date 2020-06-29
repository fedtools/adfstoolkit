function Get-ADFSTkHealth {
[cmdletbinding()]
param ()

#Get All paths
if ([string]::IsNullOrEmpty($Global:ADFSTkPaths))
{
    $Global:ADFSTkPaths = Get-ADFSTKPaths
}

$finalResult = $true

#region check script signatures
    $signatureCheck = $true
    Write-ADFSTkVerboseLog "Checking signature on module scipts..."
    $Signatures = Get-ChildItem -Path $Global:ADFSTkPaths.modulePath -Filter *.ps1 -Recurse | Get-AuthenticodeSignature
    $validSignatures = ($Signatures | ? Status -eq Valid).Count
    $invalidSignatures = ($Signatures | ? Status -eq HashMismatch).Count
    $missingSignatures = ($Signatures | ? Status -eq NotSigned).Count
    
    Write-ADFSTkVerboseLog ("{0} scripts found with valid signature(s)..." -f $validSignatures)
    Write-ADFSTkVerboseLog ("{0} scripts found with invalid signature(s)..." -f $invalidSignatures)
    Write-ADFSTkVerboseLog ("{0} scripts found with missing signature(s)..." -f $missingSignatures)

    if ($invalidSignatures -gt 0)
    {
        $signatureCheck = $false
        Write-ADFSTkLog (@"
The script(s) below have invalid signatures. The code can have been changed so they don't work as expected! 
If you don't know why this occurred, reinstallation of ADFS Toolkit is recommended.

{0} 
"@ -f ($Signatures | ? Status -eq HashMismatch | Select -ExpandProperty Path | Out-String)) -EntryType Warning
    }

    if ($missingSignatures -gt 0 -and $Global:ADFSTkSkipNotSignedCheck -ne $true)
    {
        $signatureCheck = $false
        Write-ADFSTkLog (@"
The script(s) below have one or more missing signature(s). An unreleased version of ADFS Toolkit might be used and the functionality cannot be guaranteed! 
If you don't know why this occurred, reinstallation of ADFS Toolkit is recommended.

{0} 
"@ -f ($Signatures | ? Status -eq NotSigned | Select -ExpandProperty Path | Out-String)) -EntryType Warning
    }

    if ($signatureCheck -eq $true)
    {
        Write-Verbose "Signaturecheck PASSED!"   
    }
    else
    {
        Write-Verbose "Signaturecheck FAILED!"
        $finalResult = $false
    }
#endregion
    
    return $finalResult
}
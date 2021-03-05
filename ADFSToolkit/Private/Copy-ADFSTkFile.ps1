function Copy-ADFSTkFile {
    param (
        [Parameter(Mandatory = $true,
            Position = 0)]
        [String]
        $Path,
        [Parameter(Mandatory = $true,
            Position = 1)]
        [String]
        $Destination,
        [Switch]
        $KeepSignature
    )

    if ($PSBoundParameters.ContainsKey('KeepSignature') -and $KeepSignature -ne $false) {
        Copy-Item $Path $Destination -Force
    }
    else {
        $continue = $true
        Get-Content $Path | % {
            if ($_ -eq '# SIG # Begin signature block')
            {
                $continue = $false
            }
            elseif ($continue) {
                $_
            }
        } | Out-File $Destination -Force
    }
}
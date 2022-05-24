function New-ADFSTkSalt {
    param (
        # The length fof the Salt. Default is 16
        [uint16]$Length = 16
    )

    $characters = ""
    0x30..0x39 | % { $characters += ([char]$_) }
    0x41..0x5A | % { $characters += ([char]$_) }
    0x61..0x7A | % { $characters += ([char]$_) }
    do {
        $bytes = New-Object byte[] ($Length * 2)
        $RandomGenerator = [System.Security.Cryptography.RandomNumberGenerator]::Create()
        $RandomGenerator.GetBytes($bytes)

        foreach ($byte in $bytes) {
            if ($Salt.Length -lt $Length -and $characters.Contains([char]$byte)) {
                $Salt += [char]$byte
            }
        }
    }
    until ($Salt.Length -ge $Length)

    return $Salt
}
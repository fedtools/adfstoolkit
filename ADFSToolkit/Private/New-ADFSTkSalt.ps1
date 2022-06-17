function New-ADFSTkSalt {
    param (
        # The nuber of randomized bytes in the Salt. Default is 30 which gives a salt with 40 characters.
        [uint16]$RandomizedBytes = 30
    )

    # $characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789+/="
    # # Större teckenrymd men Base64 encoda efteråt och använd det som salt
    # # 0x30..0x39 | % { $characters += ([char]$_) }
    # # 0x41..0x5A | % { $characters += ([char]$_) }
    # # 0x61..0x7A | % { $characters += ([char]$_) }
    # do {
    #     $bytes = New-Object byte[] ($Length * 2)
    #     $RandomGenerator = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    #     $RandomGenerator.GetBytes($bytes)

    #     foreach ($byte in $bytes) {
    #         if ($Salt.Length -lt $Length -and $characters.Contains([char]$byte)) {
    #             $Salt += [char]$byte
    #         }
    #     }
    # }
    # until ($Salt.Length -ge $Length)

    # $SaltBytes = [System.Text.Encoding]::Unicode.GetBytes($Salt)
    # $EncodedSalt =[Convert]::ToBase64String($SaltBytes)

    $bytes = New-Object byte[] ($RandomizedBytes)
    $RandomGenerator = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $RandomGenerator.GetBytes($bytes)

    $EncodedSalt = [Convert]::ToBase64String($bytes)

    return $EncodedSalt
}
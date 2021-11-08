function New-ADFSTkEntityHash {
param (
    [Parameter(Mandatory=$true, Position=0)]
    $SP
)

    $MD5 = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
    $UTF8 = new-object -TypeName System.Text.UTF8Encoding

    [System.BitConverter]::ToString($MD5.ComputeHash($UTF8.GetBytes($SP.InnerXml)))
}
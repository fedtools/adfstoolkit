<#
.Synopsis
   Compares two sets extremely fast
.DESCRIPTION
   Compares two sets extremely fast.
   The sets can be string arrays or an AD Group Object
.EXAMPLE
   $a = 1..100000
   $b=20000...50000
   Compare-ADFSTkObject $a $b -CompareType InFirstSetOnly

Name                           Value                                                                                                                                                                                         
----                           -----                                                                                                                                                                                         
MembersInFirstSet              100000                                                                                                                                                                                        
MembersInSecondSet             20001                                                                                                                                                                                         
MembersInCompareSet            80000                                                                                                                                                                                         
CompareType                    InFirstSetOnly                                                                                                                                                                                
CompareSet                     {20001, 20002, 20003, 20004...}                                                                                                                                                               

.EXAMPLE
   $a = 1..100000
   $b=20000...50000
   Compare-ADFSTkObject $a $b -CompareType InFirstSetOnly -Raw
   20001
   20002
   20003
   .
   .
   .
#>
function Compare-ADFSTkObject {
param (        
    [Parameter(Mandatory=$true,
                Position=0)]
    #The first set to compare
    $FirstSet,
    [Parameter(Mandatory=$true,
                Position=1)]
    #The second set to compare
    $SecondSet,
    [Parameter(Mandatory=$true,
                Position=2)]
    [ValidateSet("InFirstSetOnly","InSecondSetOnly","Union","Intersection","AddRemove")]
    $CompareType,
    [switch]$Raw
)

        
    if ($FirstSet -isnot [string[]] -and $FirstSet -isnot [int[]])
    {
        if ("Microsoft.ActiveDirectory.Management.ADGroup" -as [type] -and $FirstSet -is [Microsoft.ActiveDirectory.Management.ADGroup])
        {
            if (($FirstSet | Get-Member -MemberType Property | ? Name -eq Members) -ne $null)
            {
                $FirstSet = $FirstSet.Members.Value
            }
            else
            { 
                $FirstSet = Get-ADGroup $FirstSet.distinguishedName -Properties Members | Select -ExpandProperty members
            }
        }
    }

    if ($SecondSet -isnot [string[]] -and $SecondSet -isnot [int[]])
    {
        if ("Microsoft.ActiveDirectory.Management.ADGroup" -as [type] -and $SecondSet -is [Microsoft.ActiveDirectory.Management.ADGroup])
        {
            if (($SecondSet | Get-Member -MemberType Property | ? Name -eq Members) -ne $null)
            {
                $SecondSet = $SecondSet.Members.Value
            }
            else
            { 
                $SecondSet = Get-ADGroup $SecondSet.distinguishedName -Properties Members | Select -ExpandProperty members
            }
        }
    }
    
   if (([string]::IsNullOrEmpty($FirstSet) -or $FirstSet[0] -is [String] -or $FirstSet[0] -is [Char]) -and ([string]::IsNullOrEmpty($SecondSet) -or $SecondSet[0] -is [String] -or $SecondSet[0] -is [Char]))
    {
        [System.Collections.Generic.HashSet[String]]$FirstHashSet = $FirstSet
        [System.Collections.Generic.HashSet[String]]$SecondHashSet = $SecondSet
    }
    elseif ($FirstSet[0] -is [Int] -or $SecondSet[0] -is [Int])
    {
        [System.Collections.Generic.HashSet[Int]]$FirstHashSet = $FirstSet
        [System.Collections.Generic.HashSet[Int]]$SecondHashSet = $SecondSet
    }
    else
    {
        throw "Invalid types of object in set! Valid objects are String, Int"
    }

    if (!$Raw) 
    {
        $Info = [ordered]@{
            MembersInFirstSet = $FirstSet.Count
            MembersInSecondSet = $SecondSet.Count
            MembersInCompareset = 0
            CompareType = $CompareType
        }
    }


    switch ($CompareType)
    {
        'InFirstSetOnly' {
            if ([string]::IsNullOrEmpty($FirstHashSet)) {
                $FirstHashSet = $SecondHashSet
            }
            else {
                $FirstHashSet.ExceptWith($SecondHashSet)
            }

            if ($Raw) {
                $FirstHashSet
            }
            else {
                $Info.MembersInCompareSet = $FirstHashSet.Count
                $Info.CompareSet = $FirstHashSet
            }
        }
        'InSecondSetOnly' {
            if ([string]::IsNullOrEmpty($SecondHashSet)) {
                $SecondHashSet = $FirstHashSet
            }
            else {
                $SecondHashSet.ExceptWith($FirstHashSet)
            }

            if ($Raw) {
                $SecondHashSet
            }
            else {
                $Info.MembersInCompareSet = $SecondHashSet.Count
                $Info.CompareSet = $SecondHashSet
            }
        }
        'Union' {

            if ([string]::IsNullOrEmpty($FirstHashSet)) {
                $FirstHashSet = $SecondHashSet
            }
            elseif ([string]::IsNullOrEmpty($SecondHashSet)) {
                $FirstHashSet = @()
            }
            else {
                $FirstHashSet.UnionWith($SecondHashSet)
            }
            

            if ($Raw) {
                $FirstHashSet
            }
            else {
                $Info.MembersInCompareSet = $FirstHashSet.Count
                $Info.CompareSet = $FirstHashSet
            }
        }
        'Intersection' {
            
            if ([string]::IsNullOrEmpty($FirstHashSet)) {
                $FirstHashSet = @()
            }
            elseif ([string]::IsNullOrEmpty($SecondHashSet)) {
                $FirstHashSet = @()
            }
            else {
                $FirstHashSet.IntersectWith($SecondHashSet)
            }

            
            if ($Raw) {
                $FirstHashSet
            }
            else {
                $Info.MembersInCompareSet = $FirstHashSet.Count
                $Info.CompareSet = $FirstHashSet
            }
        }
        'AddRemove' {
            if ($FirstHashSet -is [System.Collections.Generic.HashSet[String]]) {
                $RemoveHashSet = [System.Collections.Generic.HashSet[String]]$FirstSet
                $AddHashSet = [System.Collections.Generic.HashSet[String]]$SecondSet
            }
            elseif ($FirstHashSet -is [System.Collections.Generic.HashSet[Int]]) {
                $RemoveHashSet = [System.Collections.Generic.HashSet[Int]]$FirstSet
                $AddHashSet = [System.Collections.Generic.HashSet[Int]]$SecondSet
            }

            if ([string]::IsNullOrEmpty($FirstHashSet)) {
                $AddHashSet = $SecondHashSet
                $RemoveHashSet = @()
            }
            elseif ([string]::IsNullOrEmpty($SecondHashSet)) {
                $AddHashSet = @()
                $RemoveHashSet = $FirstHashSet
            }
            else {
                $RemoveHashSet.ExceptWith($SecondHashSet)
                $AddHashSet.ExceptWith($FirstHashSet)
            }
            
            

            if ($Raw) {
                @{
                    Add = $AddHashSet
                    Remove = $RemoveHashSet
                }
            }
            else {
                $Info.RemoveSet = $RemoveHashSet
                $Info.MembersInRemoveSet = $RemoveHashSet.Count
                $Info.AddSet = $AddHashSet
                $Info.MembersInAddSet = $AddHashSet.Count
            }
        }
    }

    if (!$Raw) 
    {
        $Info
    }
}

# SIG # Begin signature block
# MIIUJwYJKoZIhvcNAQcCoIIUGDCCFBQCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUH5XM14WYgk+8Igfj0sVf2Xd8
# M9Sggg8nMIIEmTCCA4GgAwIBAgIPFojwOSVeY45pFDkH5jMLMA0GCSqGSIb3DQEB
# BQUAMIGVMQswCQYDVQQGEwJVUzELMAkGA1UECBMCVVQxFzAVBgNVBAcTDlNhbHQg
# TGFrZSBDaXR5MR4wHAYDVQQKExVUaGUgVVNFUlRSVVNUIE5ldHdvcmsxITAfBgNV
# BAsTGGh0dHA6Ly93d3cudXNlcnRydXN0LmNvbTEdMBsGA1UEAxMUVVROLVVTRVJG
# aXJzdC1PYmplY3QwHhcNMTUxMjMxMDAwMDAwWhcNMTkwNzA5MTg0MDM2WjCBhDEL
# MAkGA1UEBhMCR0IxGzAZBgNVBAgTEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UE
# BxMHU2FsZm9yZDEaMBgGA1UEChMRQ09NT0RPIENBIExpbWl0ZWQxKjAoBgNVBAMT
# IUNPTU9ETyBTSEEtMSBUaW1lIFN0YW1waW5nIFNpZ25lcjCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBAOnpPd/XNwjJHjiyUlNCbSLxscQGBGue/YJ0UEN9
# xqC7H075AnEmse9D2IOMSPznD5d6muuc3qajDjscRBh1jnilF2n+SRik4rtcTv6O
# KlR6UPDV9syR55l51955lNeWM/4Og74iv2MWLKPdKBuvPavql9LxvwQQ5z1IRf0f
# aGXBf1mZacAiMQxibqdcZQEhsGPEIhgn7ub80gA9Ry6ouIZWXQTcExclbhzfRA8V
# zbfbpVd2Qm8AaIKZ0uPB3vCLlFdM7AiQIiHOIiuYDELmQpOUmJPv/QbZP7xbm1Q8
# ILHuatZHesWrgOkwmt7xpD9VTQoJNIp1KdJprZcPUL/4ygkCAwEAAaOB9DCB8TAf
# BgNVHSMEGDAWgBTa7WR0FJwUPKvdmam9WyhNizzJ2DAdBgNVHQ4EFgQUjmstM2v0
# M6eTsxOapeAK9xI1aogwDgYDVR0PAQH/BAQDAgbAMAwGA1UdEwEB/wQCMAAwFgYD
# VR0lAQH/BAwwCgYIKwYBBQUHAwgwQgYDVR0fBDswOTA3oDWgM4YxaHR0cDovL2Ny
# bC51c2VydHJ1c3QuY29tL1VUTi1VU0VSRmlyc3QtT2JqZWN0LmNybDA1BggrBgEF
# BQcBAQQpMCcwJQYIKwYBBQUHMAGGGWh0dHA6Ly9vY3NwLnVzZXJ0cnVzdC5jb20w
# DQYJKoZIhvcNAQEFBQADggEBALozJEBAjHzbWJ+zYJiy9cAx/usfblD2CuDk5oGt
# Joei3/2z2vRz8wD7KRuJGxU+22tSkyvErDmB1zxnV5o5NuAoCJrjOU+biQl/e8Vh
# f1mJMiUKaq4aPvCiJ6i2w7iH9xYESEE9XNjsn00gMQTZZaHtzWkHUxY93TYCCojr
# QOUGMAu4Fkvc77xVCf/GPhIudrPczkLv+XZX4bcKBUCYWJpdcRaTcYxlgepv84n3
# +3OttOe/2Y5vqgtPJfO44dXddZhogfiqwNGAwsTEOYnB9smebNd0+dmX+E/CmgrN
# Xo/4GengpZ/E8JIh5i15Jcki+cPwOoRXrToW9GOUEB1d0MYwggUZMIIEAaADAgEC
# AhANucYRs6r/dGB7AgZevKrFMA0GCSqGSIb3DQEBCwUAMGUxCzAJBgNVBAYTAlVT
# MRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5j
# b20xJDAiBgNVBAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0xNDEx
# MTgxMjAwMDBaFw0yNDExMTgxMjAwMDBaMG0xCzAJBgNVBAYTAk5MMRYwFAYDVQQI
# Ew1Ob29yZC1Ib2xsYW5kMRIwEAYDVQQHEwlBbXN0ZXJkYW0xDzANBgNVBAoTBlRF
# UkVOQTEhMB8GA1UEAxMYVEVSRU5BIENvZGUgU2lnbmluZyBDQSAzMIIBIjANBgkq
# hkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAquLnIC+sEJX6zSTl+KDf9aKtn7yzyeH4
# H8Q+5JZBbbvnA/AMFHG9pjhRt1A5pzn2Qm3iXMSe/6t41b1nAyHpbgTMRt/FhySU
# n/3WLAVhg5Oy9eF3ZCq61VDzttpv0Iu8fz5rAO5cszS/UMD4yPB9V350CkivbUhM
# i2+KXiO+dstdhHhWO4hnm9GIYKIIRAeIiabD8twq4HNswpuEJvcUPotKqGkI9JOJ
# 6B9p67QqdTILGY98swy4WuRGtGRrx9BQm/CAtE81cZ8gf1nIVGbszTMT3wkyhRAC
# YWg8tJIkYLqg0ry1xwe9/FDqNGAIHwKhjx+3LP1apkmAuTn6WUn5GQIDAQABo4IB
# uzCCAbcwEgYDVR0TAQH/BAgwBgEB/wIBADAOBgNVHQ8BAf8EBAMCAYYwEwYDVR0l
# BAwwCgYIKwYBBQUHAwMweQYIKwYBBQUHAQEEbTBrMCQGCCsGAQUFBzABhhhodHRw
# Oi8vb2NzcC5kaWdpY2VydC5jb20wQwYIKwYBBQUHMAKGN2h0dHA6Ly9jYWNlcnRz
# LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcnQwgYEGA1Ud
# HwR6MHgwOqA4oDaGNGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFz
# c3VyZWRJRFJvb3RDQS5jcmwwOqA4oDaGNGh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNv
# bS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcmwwPQYDVR0gBDYwNDAyBgRVHSAA
# MCowKAYIKwYBBQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwHQYD
# VR0OBBYEFDIKwQzBaD5XqC35eSLljpzpRI4yMB8GA1UdIwQYMBaAFEXroq/0ksuC
# MS1Ri6enIZ3zbcgPMA0GCSqGSIb3DQEBCwUAA4IBAQBErVAKGa8D4fOknsozyzRE
# lbTq3fi5SLXlapnDtwGOrtXEcx59Wgj9Gb8gTMUBu8iy2xDJ2SsN3c5xPNxbrrln
# S++9sESYuGEp3Kh6c7IUvXQ/MFzDecAM9Fbcs/7hiXhFpYfoWSiPRIttBj+xNsQw
# 7nRsVMvEA9dveBrjbEN2FUaeIklZl0043htM0nyWG/y61+l6GDAXLNWGiS7Qmhk+
# NfLGK75RSWdJHWUhr0IiTg1NDxoC6ZuCduf8irB7dVZN6j+QD4onBFUwE3pTof72
# XqL2STlUXwPJi2o1zjCoAuBAFe0VlRAdBmPv742jmuHBWmCaMYSXufCLkCpqy8ci
# MIIFaTCCBFGgAwIBAgIQCW5rqoS6iEaBVRWKc8qoWDANBgkqhkiG9w0BAQsFADBt
# MQswCQYDVQQGEwJOTDEWMBQGA1UECBMNTm9vcmQtSG9sbGFuZDESMBAGA1UEBxMJ
# QW1zdGVyZGFtMQ8wDQYDVQQKEwZURVJFTkExITAfBgNVBAMTGFRFUkVOQSBDb2Rl
# IFNpZ25pbmcgQ0EgMzAeFw0xNjA5MTkwMDAwMDBaFw0xOTA5MjQxMjAwMDBaMIG1
# MQswCQYDVQQGEwJTRTEXMBUGA1UECAwOw5ZzdGVyZ8O2dGxhbmQxEzARBgNVBAcM
# CkxpbmvDtnBpbmcxIDAeBgNVBAoMF0xpbmvDtnBpbmdzIHVuaXZlcnNpdGV0MQ4w
# DAYDVQQLEwVMSVVJVDEgMB4GA1UEAwwXTGlua8O2cGluZ3MgdW5pdmVyc2l0ZXQx
# JDAiBgkqhkiG9w0BCQEWFWpvaGFuLnBldGVyc29uQGxpdS5zZTCCASIwDQYJKoZI
# hvcNAQEBBQADggEPADCCAQoCggEBAK+Gsc63+pniTFtRgCwTDWvLlWnDFmsBxmfA
# folhD2l9rx3Gwmn/GAFS5xW64kIacL80T+iMc89qe/7ozmvlU9Yhj0qz4pxayV8j
# TrOXsyFkKsMkyE5WauK1yEwBMspXsmCUejV5FX+KB8S1lbUtwVVTVe8vLDWBRxIU
# mTMgMpgi/askOlAJQkhQ3CgUSWv00SwSbjORZZ2FzojmOs3ckRZU0nIrGRY4heXK
# s7Q7TxlpL/OeEJs2FfzMWP+zEvVrTGUd/hmlM08a2luZXfPQfzaPh33WUs6IEusg
# +3bQOQfNEHZcvfiB3r1gVUKT87Hz3dhrnTJ9P7soG+kRbIDCoAsCAwEAAaOCAbow
# ggG2MB8GA1UdIwQYMBaAFDIKwQzBaD5XqC35eSLljpzpRI4yMB0GA1UdDgQWBBQK
# ll4K2UPnGSzavcxKfSUdFklTVDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYI
# KwYBBQUHAwMwewYDVR0fBHQwcjA3oDWgM4YxaHR0cDovL2NybDMuZGlnaWNlcnQu
# Y29tL1RFUkVOQUNvZGVTaWduaW5nQ0EzLmNybDA3oDWgM4YxaHR0cDovL2NybDQu
# ZGlnaWNlcnQuY29tL1RFUkVOQUNvZGVTaWduaW5nQ0EzLmNybDBMBgNVHSAERTBD
# MDcGCWCGSAGG/WwDATAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy5kaWdpY2Vy
# dC5jb20vQ1BTMAgGBmeBDAEEATB2BggrBgEFBQcBAQRqMGgwJAYIKwYBBQUHMAGG
# GGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBABggrBgEFBQcwAoY0aHR0cDovL2Nh
# Y2VydHMuZGlnaWNlcnQuY29tL1RFUkVOQUNvZGVTaWduaW5nQ0EzLmNydDAMBgNV
# HRMBAf8EAjAAMA0GCSqGSIb3DQEBCwUAA4IBAQA//uISIy+v0S1UH1b6zWFhgFPw
# wZvtAi+WzDYlfNHM1ZKQNdGbdU5uwFnaToPoX3z5UzDEv1hOXLgCLtI3rNnj0O0J
# BaWiLtNYYeRwAV3dDpHcAbiHvViMbxIA4zCeckmxoe0HrmKs1CFCPVYM5aLXjmEP
# aWPf2GZ6xC65g85M2aE8tFNMTOFmhZ/MiiMXNYGMT78L7yKDly59+iFbJZioBnss
# ktKo+s73Cgp+PbXB0/ylQ3G7xpDeiaN0i55S/OtMbKg2lZu6RdQQwzmpfUHu8VbI
# fOnfwNPY8o+OJaWl7fJDDzuFnbFnszFD1sN8eIQXf+yOxzrPw205ka7Z2SYSMYIE
# ajCCBGYCAQEwgYEwbTELMAkGA1UEBhMCTkwxFjAUBgNVBAgTDU5vb3JkLUhvbGxh
# bmQxEjAQBgNVBAcTCUFtc3RlcmRhbTEPMA0GA1UEChMGVEVSRU5BMSEwHwYDVQQD
# ExhURVJFTkEgQ29kZSBTaWduaW5nIENBIDMCEAlua6qEuohGgVUVinPKqFgwCQYF
# Kw4DAhoFAKB4MBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkD
# MQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJ
# KoZIhvcNAQkEMRYEFJ9AlH3lOBQoN3TLsCINp/Awa2h0MA0GCSqGSIb3DQEBAQUA
# BIIBADL68EimMblQMQfj9zCmvbl8EKa0g5qlJ2KAdyY+qHNSEkUSk2AUBA9gdUzg
# zdg0nt+SPbMQaL+3zLNk7cgDw20wZnrYvHYg0s4FxyBt1qmJ3RQjYRSX0UhBP1e3
# Q0zLl2yx+P9Kl8bHxLn8HynFotPc6yWZ7VNRaJle/vVnMK8vX8PK1YX6yeOxFTNU
# HLHN9ii0qh2NeVXLaPHni9hqbunPFjE50kpFujmwvFV+pAJb1E8ZiSnhpT8wVbd2
# qG1bGa2SLiABOnvjxXP/Y62DyPcazxla6XijTjzyJfx/Rt3Zyrn/YkV6ciEaoA0G
# 7prlACoVMJZOZYPorDQRmk/KgHihggJDMIICPwYJKoZIhvcNAQkGMYICMDCCAiwC
# AQEwgakwgZUxCzAJBgNVBAYTAlVTMQswCQYDVQQIEwJVVDEXMBUGA1UEBxMOU2Fs
# dCBMYWtlIENpdHkxHjAcBgNVBAoTFVRoZSBVU0VSVFJVU1QgTmV0d29yazEhMB8G
# A1UECxMYaHR0cDovL3d3dy51c2VydHJ1c3QuY29tMR0wGwYDVQQDExRVVE4tVVNF
# UkZpcnN0LU9iamVjdAIPFojwOSVeY45pFDkH5jMLMAkGBSsOAwIaBQCgXTAYBgkq
# hkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0xNzA1MTAwNzU2
# MzNaMCMGCSqGSIb3DQEJBDEWBBT0au7Skqd4yT96poggf/3YAaT7RzANBgkqhkiG
# 9w0BAQEFAASCAQBuzVZlYmFUJiNY4GHy2Q5aRdeX7rEpzJQqJqmutCAz8V4/8w6K
# lp9tmj3LlM49cUOjSEa0KvSA7eVomKfy9u3z6k8rD8i1Rjsy40Ru/jDg/H7J4vGc
# vLukRTmegrQFzMJPybYoN1EjWlNhwSgzJ+qbH9JL4lRyGAJF+e1ivg6Qnzsnd2XR
# WwOKPoUaPaz5hhmED3T/WxOr2MqNEwG9jCUwbUvm03cI1otUQIUA8b+udGNRYfRO
# uNxZ4uhepUJbPdDhfA5QGthdOzcqn/nUdmvUsibHAjhXGcg90HTHgYbC176E5dZY
# m6UC82a3Rc/o7vIp99xYoQ+tsefRbV5NjSZC
# SIG # End signature block

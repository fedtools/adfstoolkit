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
                [AllowEmptyCollection()]
    #The first set to compare
    $FirstSet =@(),
    [Parameter(Mandatory=$true,
                Position=1)]
                [AllowEmptyCollection()]
    #The second set to compare
    $SecondSet =@(),
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
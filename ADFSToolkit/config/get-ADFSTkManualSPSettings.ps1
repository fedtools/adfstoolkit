function get-ADFSTkManualSPSettings
{

# HOW TO USE THIS FILE
#
# As of 0.9.45, this file purposely abstracts out overrides to user managed PowerShell.
# Please see the help section.
#

# We attempt to detect existance of the function which should contain the collection
# of service provider

    #Get All paths
    if ([string]::IsNullOrEmpty($Global:ADFSTkPaths))
    {
        $Global:ADFSTkPaths = Get-ADFSTKPaths
    }

    try {
        #Attempt to Get local override
        if ([string]::IsNullOrEmpty($Settings.configuration.LocalRelyingPartyFile))
        {
            Write-ADFSTkLog (Get-ADFSTkLanguageText msNoConfiguredFile) -EntryType Information
        }
        else
        {
            # build the file path, source the file, invoke the function/method that the file is named
            $localRelyingPartyFileFullPath = Join-Path $Global:ADFSTkPaths.institutionDir $Settings.configuration.LocalRelyingPartyFile
              
            $myRelyingPartyMethodToInvoke = [IO.Path]::GetFileNameWithoutExtension($localRelyingPartyFileFullPath)

            if (Test-Path -Path $localRelyingPartyFileFullPath )
            {
                . $localRelyingPartyFileFullPath
                $ManualSPSettings = & $myRelyingPartyMethodToInvoke

            }
            else
            {
                Write-ADFSTkLog (Get-ADFSTkLanguageText msNoFileFound -f $Settings.configuration.LocalRelyingPartyFile) -EntryType Information 
            }
        }


    # ADFSToolkit ships with empty RP/SP settings now
    # 
    # Sites can pass in their settings by $ADFSTkSiteSPSettings 
    # Examples are below.
    
    # This returns the hashtable of hashtables to whomever invoked this function
    
    $ManualSPSettings

}
    Catch
    {
        Throw $_
    }



<#
.SYNOPSIS
As of 0.9.45 and later, this file detects the existance of a site's  Relying Party/Service provider attribute release definitions.
If the variable: ADFSTkSiteSPSettings exists, we will import these site specific settings.


.DESCRIPTION

This file is a harness to allow a site admin to configure per RP/SP attribute release policies for ADFSToolkit.
ADFSToolkit's default behaviour for Entity Categories such as Research and Scholarship are handled elsewhere in the ADFSToolkit Module.


How this Powershell Cmdlet works:

This file is delivered code complete, but returns an empty result.

Creation of this file: 

Usually created when get-ADFSTkConfiguration is invoked which uses this file as a template (minus signature):

 (Get-Module -Name ADFSToolkit).ModuleBase\config\default\en-US\get-ADFSTkManualSPSettings-dist.ps1

Alternatively, it can be created by hand and placed in c:\ADFSToolkit\<version>\config and sourced by command:

c:\ADFSToolkit\sync-ADFSTkAggregates.ps1

In the site specific file, for each entity we want to change the attribute handling policy of ADFS, we:
   -  create an empty TransformRules Hashtable
   -  assign 1 or more specific transform rules that have a corelating TransformRules Object
   -  When all transform rules are described, the set of transforms is inserted into the Hashtable we return

    Clever transforms can be used as well to supercede or inject elements into RP/SP settings. Some are detailed in the examples.

    To see example code blocks invoke detailed help by: get-help get-ADFSTkManualSPSettings -Detailed
   
.INPUTS

none

.OUTPUTS

a Powershell Hashtable structured such that ADFSToolkit may ingest and perform attribute release.

.EXAMPLE
### CAF test Federation Validator service attribute release
# $IssuanceTransformRuleManualSP = @{} uncomment when testing example. Needed only once per file to contain set of changes

$TransformRules = [Ordered]@{}
$TransformRules.givenName = $AllTransformRules.givenName
$TransformRules.sn = $AllTransformRules.sn
$TransformRules.cn = $AllTransformRules.cn
$TransformRules.eduPersonPrincipalName = $AllTransformRules.eduPersonPrincipalName
$TransformRules.mail = $AllTransformRules.mail
$TransformRules.eduPersonScopedAffiliation = $AllTransformRules.eduPersonScopedAffiliation
$IssuanceTransformRuleManualSP["https://validator.caftest.canarie.ca/shibboleth"] = $TransformRules

    
.EXAMPLE
### Lynda.com attribute release
# $IssuanceTransformRuleManualSP = @{} uncomment when testing example. Needed only once per file to contain set of changes

    
$TransformRules = [Ordered]@{}
$TransformRules.givenName = $AllTransformRules.givenName
$TransformRules.sn = $AllTransformRules.sn
$TransformRules.cn = $AllTransformRules.cn
$TransformRules.eduPersonPrincipalName = $AllTransformRules.eduPersonPrincipalName
$TransformRules.mail = $AllTransformRules.mail
$TransformRules.eduPersonScopedAffiliation = $AllTransformRules.eduPersonScopedAffiliation
$IssuanceTransformRuleManualSP["https://shib.lynda.com/shibboleth-sp"] = $TransformRules

.EXAMPLE
### advanced ADFS Transform rule #1 'from AD'    
# $IssuanceTransformRuleManualSP = @{} uncomment when testing example. Needed only once per file to contain set of changes

$TransformRules = [Ordered]@{}
$TransformRules."From AD" = @"
 c:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/windowsaccountname", 
 Issuer == "AD AUTHORITY"]
  => issue(store = "Active Directory", 
 types = ("http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn", 
 "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name", 
 "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress", 
 "http://liu.se/claims/eduPersonScopedAffiliation", 
 "http://liu.se/claims/Department"), 
 query = ";userPrincipalName,displayName,mail,eduPersonScopedAffiliation,department;{0}", param = c.Value);
 "@
$IssuanceTransformRuleManualSP."advanced.entity.id.org" = $TransformRules

.EXAMPLE
### advanced ADFS Transform rule #2 
# $IssuanceTransformRuleManualSP = @{} uncomment when testing example. Needed only once per file to contain set of changes

$TransformRules = [Ordered]@{}
$TransformRules.mail = [PSCustomObject]@{
Rule=@"
@RuleName = "compose mail address as name@schacHomeOrganization"
c:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name", Value !~ "^.+\\"]
=> issue(Type = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier", Value = c.Value + "@$($Settings.configuration.StaticValues.schacHomeOrganization)");
"@
Attribute="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"
     }
$IssuanceTransformRuleManualSP["https://advanced.rule.two.org"] = $TransformRules
    
.EXAMPLE
### verify-i.myunidays.com
# $IssuanceTransformRuleManualSP = @{} uncomment when testing example. Needed only once per file to contain set of changes

$TransformRules = [Ordered]@{}
$TransformRules["eduPersonScopedAffiliation"] = $AllTransformRules["eduPersonScopedAffiliation"]
$TransformRules["eduPersonTargetedID"] = $AllTransformRules["eduPersonTargetedID"]
$IssuanceTransformRuleManualSP["https://verify-i.myunidays.com/shibboleth"] = $TransformRules

.EXAMPLE
### Release just transient-id
# $IssuanceTransformRuleManualSP = @{} uncomment when testing example. Needed only once per file to contain set of changes

$TransformRules = [Ordered]@{}
$TransformRules.'transient-id' = $AllTransformRules.'transient-id'
$IssuanceTransformRuleManualSP["https://just-transientid.org"] = $TransformRules

.NOTES

Details about Research and Scholarship Entity Category: https://refeds.org/category/research-and-scholarship

#>

}
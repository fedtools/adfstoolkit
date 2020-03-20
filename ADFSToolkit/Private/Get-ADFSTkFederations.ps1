function Get-ADFSTkFederations {
[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [switch]$Force
)

    #Get All paths
    if ([string]::IsNullOrEmpty($Global:ADFSTkPaths))
    {
        $Global:ADFSTkPaths = Get-ADFSTKPaths
    }

    $federationsFile = $Global:ADFSTkPaths.federationsFile
    $defaultFederationsFile = Join-Path $Global:ADFSTkPaths.moduleConfigDefaultDir federations.xml


    if ($PSBoundParameters.ContainsKey("Force"))
    {
        $executionList = @('URL', 'Cache', 'Default')
    }
    else
    {
        $executionList = @('Cache', 'URL', 'Default')
    }

    $retry = $true
    $i = 0
    do
    {
        $fedXML = Get-ADFSTkFederationsFromSelection -Selection $executionList[$i]
        $retry = ($fedXML -eq $null)
        
        $i++
    }
    while ($retry -eq $true -and $i -lt $executionList.Count)

    $fedXML
}

function Get-ADFSTkFederationsFromSelection {
[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [ValidateSet('URL', 'Cache', 'Default')]
    $Selection
)

     switch ($Selection)
     {
         'URL' {
            $url = 'https://technical.edugain.org/status'

            Write-ADFSTkHost federationDownloadCanTakeTimeWarning -Style Info
            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText federationGetFederationFromURL -f $url)

            try {
                $web = Invoke-WebRequest -Uri $url 

                $federations = $web.AllElements | ? { $_.Class -eq 'member-div' }

                [xml]$fedXML = New-Object System.Xml.XmlDocument
                $fedXML.AppendChild($fedXML.CreateXmlDeclaration("1.0",$null,$null)) | Out-Null
        
                $federationsNode = $fedXML.CreateNode("element","Federations",$null)
    
                foreach ($federation in $federations)
                {
                    $federationMainNode = $fedXML.CreateNode("element","Federation",$null)
        
                    $federationNode = $fedXML.CreateNode("element","Name",$null)
                    $federationNode.InnerText = $federation.innerText.TrimStart().TrimEnd()
                    $federationMainNode.AppendChild($federationNode) | Out-Null

                    $federationNode = $fedXML.CreateNode("element","Id",$null)
                    $federationNode.InnerText = $federation.data_value
                    $federationMainNode.AppendChild($federationNode) | Out-Null

                    $federationsNode.AppendChild($federationMainNode) | Out-Null
                }

                $fedXML.AppendChild($federationsNode) | Out-Null

                $fedXML.Save($federationsFile)

                Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText cDone)

                return $fedXML
             }
             catch {
                Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText federationCouldNotGetFederationsFromURL -f $_)
                return $null
             }

         }
         'Cache' {
            if (Test-Path $federationsFile)
            {
                try {
                    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText federationGettingListFromCachedFile)
                    [XML]$fedXML = Get-Content $federationsFile
                    return $fedXML
                }
                catch {
                    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText federationCouldNotGetFederationsFromCache -f $_)
                    return $null
                }
            }
            else
            {
                Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText federationCouldNotFindCachedFederationsFile)
                return $null
            }
         }
         'Default' {
            try {
                Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText federationGettingListFromDefaultFile)
                [XML]$fedXML = Get-Content $defaultFederationsFile
                return $fedXML
            }
            catch {
                Write-ADFSTkLog (Get-ADFSTkLanguageText federationCouldNotGetFederationsFromDefaultFile) -MajorFault
                return $null
            }
         }
     }
}
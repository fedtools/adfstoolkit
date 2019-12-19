function Get-ADFSTkFederations {
param (
    [switch]$Force
)

    #Get All paths
    $ADFSTKPaths = Get-ADFSTKPaths

    $federationsFile = $ADFSTKPaths.federationsFile

    if (!$PSBoundParameters.ContainsKey("Force") -and (Test-Path $federationsFile))
    {
        [XML]$fedXML = Get-Content $federationsFile
    }
    else
    {

        $url = 'https://technical.edugain.org/status'

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
    }

    $fedXML
}
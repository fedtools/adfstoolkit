function Add-ADFSTkXML {
    param (
        $Xml, 
        $NodeName,
        $XPathParentNode,
        $RefNodeName,
        $Value = [string]::Empty
    )
    
    $configurationNode = Select-Xml -Xml $Xml -XPath $XPathParentNode
    if ($configurationNode.Node.$NodeName -eq $null) {
        $configurationNodeChild = $Xml.CreateNode("element", $NodeName, $null)
        $configurationNodeChild.InnerText = $Value
    
        if ($PSBoundParameters.ContainsKey('RefNodeName')) {
            $refNode = Select-Xml -Xml $Xml -XPath "$XPathParentNode/$RefNodeName"
            if ($refNode -is [Object[]]) {
                $refNode = $refNode[-1]
            }
            $configurationNode.Node.InsertAfter($configurationNodeChild, $refNode.Node) | Out-Null
        }
        else {
            $configurationNode.Node.appendChild($configurationNodeChild) | Out-Null
        }
    }
}
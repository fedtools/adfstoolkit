function Add-ADFSTkXML {
    param (
        $NodeName,
        $XPathParentNode,
        $RefNodeName,
        $Value = [string]::Empty
    )
    
    $configurationNode = Select-Xml -Xml $config -XPath $XPathParentNode
    $configurationNodeChild = $config.CreateNode("element", $NodeName, $null)
    $configurationNodeChild.InnerText = $Value
    
    if ($PSBoundParameters.ContainsKey('RefNodeName')) {
        $refNode = Select-Xml -Xml $config -XPath "$XPathParentNode/$RefNodeName"
        if ($refNode -is [Object[]]) {
            $refNode = $refNode[-1]
        }
        $configurationNode.Node.InsertAfter($configurationNodeChild, $refNode.Node) | Out-Null
    }
    else {
        $configurationNode.Node.appendChild($configurationNodeChild) | Out-Null
        
    }
}
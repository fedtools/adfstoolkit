function Add-ADFSTkXMLNode {
    param (
        $XPathParentNode,
        $Node
    )
    
    $configurationNode = Select-Xml -Xml $config -XPath $XPathParentNode
    $configurationNode.Node.AppendChild($config.ImportNode($Node, $true)) | Out-Null
}
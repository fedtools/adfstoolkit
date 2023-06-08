function Set-ADFSTkConfiguration {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        $OutputLanguage,
        $FticksServer,
        $FticksSalt,
        $FticksLastRecordId
    )

    if (!(Test-Path $Global:ADFSTKPaths.mainConfigFile)) {
        Write-ADFSTkLog (Get-ADFSTkLanguageText mainconfNoConfigFileFound) -MajorFault
    }
    
    try {
        [xml]$config = Get-Content $Global:ADFSTKPaths.mainConfigFile
    }
    catch {
        Write-ADFSTkLog (Get-ADFSTkLanguageText mainconfCouldNotParseConfigFile -f $_) -MajorFault
    }

    #OutputLanguage
    if ($PSBoundParameters.ContainsKey('OutputLanguage')) {
        if ($config.Configuration.OutputLanguage -eq $null) {
            Add-ADFSTkXML -NodeName "OutputLanguage" -XPathParentNode "Configuration" -RefNodeName "ConfigVersion" -Value $OutputLanguage
        }
        else {
            $OutpuLanguageNode = Select-Xml -Xml $config -XPath "Configuration/OutputLanguage"
            $OutpuLanguageNode.Node.innerText = $OutputLanguage
        }
    }
    
    #Fticks
    if ($PSBoundParameters.ContainsKey('FticksServer') -or $PSBoundParameters.ContainsKey('FticksSalt') -or $PSBoundParameters.ContainsKey('FticksLastRecordId')) {
        if ($config.Configuration.Fticks -eq $null) {
            Add-ADFSTkXML -NodeName "Fticks" -XPathParentNode "Configuration" -RefNodeName "OutputLanguage"
        }
    }

    #FticksServer
    if ($PSBoundParameters.ContainsKey('FticksServer')) {
        if ($config.Configuration.Fticks.Server -eq $null) {
            Add-ADFSTkXML -NodeName "Server" -XPathParentNode "Configuration/Fticks" -Value $FticksServer
        }
        else {
            $OutpuLanguageNode = Select-Xml -Xml $config -XPath "Configuration/Fticks/Server"
            $OutpuLanguageNode.Node.innerText = $FticksServer
        }
    }

    #FticksSalt
    if ($PSBoundParameters.ContainsKey('FticksSalt')) {
        if ($config.Configuration.Fticks.Salt -eq $null) {
            Add-ADFSTkXML -NodeName "Salt" -XPathParentNode "Configuration/Fticks" -Value $FticksSalt
        }
        else {
            $OutpuLanguageNode = Select-Xml -Xml $config -XPath "Configuration/Fticks/Salt"
            $OutpuLanguageNode.Node.innerText = $FticksSalt
        }
    }

    #FticksLastRecordId
    if ($PSBoundParameters.ContainsKey('FticksLastRecordId')) {
        if ($config.Configuration.Fticks.LastRecordId -eq $null) {
            Add-ADFSTkXML -NodeName "LastRecordId" -XPathParentNode "Configuration/Fticks" -Value $FticksLastRecordId
        }
        else {
            $OutpuLanguageNode = Select-Xml -Xml $config -XPath "Configuration/Fticks/LastRecordId"
            $OutpuLanguageNode.Node.innerText = $FticksLastRecordId
        }
    }

    #Save the configuration file
    #Don't save the configuration file if -WhatIf is present
    if ($PSCmdlet.ShouldProcess($Global:ADFSTkPaths.mainConfigFile, "Save")) {
        try {
            $config.Save($Global:ADFSTkPaths.mainConfigFile)
            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText mainconfConfigItemAdded)
            $Global:ADFSTkConfiguration = Get-ADFSTkConfiguration
        }
        catch {
            throw $_
        }
    }
}
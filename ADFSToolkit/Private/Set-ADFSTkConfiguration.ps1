function Set-ADFSTkConfiguration {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        $OutputLanguage,
        $FticsServer,
        $FticsSalt,
        $FticsLastRecordId
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
    
    #Ftics
    if ($PSBoundParameters.ContainsKey('FticsServer') -or $PSBoundParameters.ContainsKey('FticsSalt') -or $PSBoundParameters.ContainsKey('FticsLastRecordId')) {
        if ($config.Configuration.Ftics -eq $null) {
            Add-ADFSTkXML -NodeName "Ftics" -XPathParentNode "Configuration" -RefNodeName "OutputLanguage"
        }
    }

    #FticsServer
    if ($PSBoundParameters.ContainsKey('FticsServer')) {
        if ($config.Configuration.Ftics.Server -eq $null) {
            Add-ADFSTkXML -NodeName "Server" -XPathParentNode "Configuration/Ftics" -Value $FticsServer
        }
        else {
            $OutpuLanguageNode = Select-Xml -Xml $config -XPath "Configuration/Ftics/Server"
            $OutpuLanguageNode.Node.innerText = $FticsServer
        }
    }

    #FticsSalt
    if ($PSBoundParameters.ContainsKey('FticsSalt')) {
        if ($config.Configuration.Ftics.Salt -eq $null) {
            Add-ADFSTkXML -NodeName "Salt" -XPathParentNode "Configuration/Ftics" -Value $FticsSalt
        }
        else {
            $OutpuLanguageNode = Select-Xml -Xml $config -XPath "Configuration/Ftics/Salt"
            $OutpuLanguageNode.Node.innerText = $FticsSalt
        }
    }

    #FticsLastRecordId
    if ($PSBoundParameters.ContainsKey('FticsLastRecordId')) {
        if ($config.Configuration.Ftics.LastRecordId -eq $null) {
            Add-ADFSTkXML -NodeName "LastRecordId" -XPathParentNode "Configuration/Ftics" -Value $FticsLastRecordId
        }
        else {
            $OutpuLanguageNode = Select-Xml -Xml $config -XPath "Configuration/Ftics/LastRecordId"
            $OutpuLanguageNode.Node.innerText = $FticsLastRecordId
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
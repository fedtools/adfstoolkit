function New-ADFSTkConfiguration
{
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$Passthru
)

   #Get All paths  and assert they exist  
   if ([string]::IsNullOrEmpty($Global:ADFSTkPaths))
    {  
        $Global:ADFSTkPaths = Get-ADFSTKPaths
    
    }
    
    Write-ADFSTkHost mainconfStartMessage -Style Info -AddLinesOverAndUnder
    
    if (Test-Path $Global:ADFSTKPaths.mainConfigFile)
    {
        Write-ADFSTkLog -Message (Get-ADFSTkLanguageText mainconfConfigFileExists) -EntryType Warning
        
        if (Get-ADFSTkAnswer (Get-ADFSTkLanguageText mainconfDoCreateConfigFile) -Caption (Get-ADFSTkLanguageText cFileAlreadyExists))
        {
            $file = Get-ChildItem $Global:ADFSTKPaths.mainConfigFile
            $backupFilename = "{0}_backup_{1}{2}" -f $file.BaseName, (Get-Date).tostring("yyyyMMdd_HHmmss"), $file.Extension

            $backupFile = Move-Item -Path $Global:ADFSTKPaths.mainConfigFile -Destination (Join-Path $Global:ADFSTKPaths.mainBackupDir $backupFilename) -PassThru
            
            Write-ADFSTkHost mainconfOldConfigBackedUp -f $backupFile.FullName -Style Value
        }
        else
        {
            Write-ADFSTkLog (Get-ADFSTkLanguageText mainconfAbortDueToExistingConfFile) -MajorFault
        }
    }

    #select federation

    Write-Host " "
    Write-ADFSTkHost mainconfChooseFederationMessage -Style Info -AddSpaceAfter
    Read-Host (Get-ADFSTkLanguageText cPressEnterKey) | Out-Null

    try {
        $feds = Get-ADFSTkFederations
        $chosenFed = $feds.Federations.Federation | Out-GridView -Title (Get-ADFSTkLanguageText cChooseFederation) -PassThru
    
        Write-ADFSTkHost mainconfChosenFederation -f $chosenFed.Id -Style Value -AddSpaceAfter
    }
    catch {
        #What to do then???
    }
    Write-ADFSTkHost -WriteLine -AddSpaceAfter

    #endregion

    #region current institution config files

    Write-ADFSTkHost mainconfSearchForExistingInstConfFile -Style Info

    $currentConfigs = Get-ChildItem $Global:ADFSTKPaths.institutionDir -Filter '*.xml' `
                                                                -Recurse | ? {$_.Directory.Name -notcontains 'backup'} | `
                                                                            Select Directory, Name, LastWriteTime | `
                                                                            Sort Directory,Name
    $selectedConfigs = $null
    
    if ($currentConfigs.count -eq 0){
        Write-ADFSTkHost mainconfNoInstConfigsFound -Style Attention -AddLinesOverAndUnder
    }
    else
    {
        Write-ADFSTkHost cFilesFound -f $currentConfigs.count -Style Value
        Write-ADFSTkHost -WriteLine
    }

    if (![string]::IsNullOrEmpty($currentConfigs))
    {
        Write-ADFSTkHost mainconfSelectConfFilesToAddToMainConf -Style Info -AddSpaceAfter
        Read-Host (Get-ADFSTkLanguageText cPressEnterKey) | Out-Null
        
        $selectedConfigs = $currentConfigs | Out-GridView -Title (Get-ADFSTkLanguageText mainconfSelectInstConfFilesTohandle) -OutputMode Multiple
                      
        Write-ADFSTkHost cChosen -f ($selectedConfigs.Name -join ',') -Style Value -AddSpaceAfter
        Write-ADFSTkHost -WriteLine -AddSpaceAfter
    }
    

    #endregion

    #region Main config

    [xml]$config = New-Object System.Xml.XmlDocument
    $config.AppendChild($config.CreateXmlDeclaration("1.0","UTF-8",$null)) | Out-Null
        
    $configurationNode = $config.CreateNode("element","Configuration",$null)
        
    $configVersionNode = $config.CreateNode("element","ConfigVersion",$null)
    $configVersionNode.InnerText = "1.0"

    $configurationNode.AppendChild($configVersionNode) | Out-Null

    $OutputLanguageNode = $config.CreateNode("element","OutputLanguage",$null)
    $OutputLanguageNode.InnerText = $Global:ADFSTkselectedLanguage

    $configurationNode.AppendChild($OutputLanguageNode) | Out-Null

    $config.AppendChild($configurationNode) | Out-Null
    #endregion 

   #region Federation config
    $federationConfig = $config.CreateNode("element","FederationConfig",$null)
    
    $federationConfigFederation = $config.CreateNode("element","Federation",$null)

    $federationConfigFederationName = $config.CreateNode("element","FederationName",$null)
    
    if ($chosenFed -ne $null)
    {
        $federationConfigFederationName.InnerText = $chosenFed.Id
    }

    $federationConfigFederation.AppendChild($federationConfigFederationName) | Out-Null

    $federationConfigFederationSigningThumbprint = $config.CreateNode("element","SigningThumbprint",$null)
    $federationConfigFederation.AppendChild($federationConfigFederationSigningThumbprint) | Out-Null

    $federationConfigFederationURL = $config.CreateNode("element","URL",$null)
    $federationConfigFederation.AppendChild($federationConfigFederationURL) | Out-Null

    $federationConfig.AppendChild($federationConfigFederation) | Out-Null
    
    $config.Configuration.AppendChild($federationConfig) | Out-Null

    #endregion

    #region config files
    
    $configFiles = $config.CreateNode("element","ConfigFiles",$null)

    foreach ($selectedConfig in $selectedConfigs)
    {
        $node = $config.CreateNode("element","ConfigFile",$null)
        $node.InnerText = Join-Path $selectedConfig.Directory $selectedConfig.Name
        $node.SetAttribute("enabled","false")
        $configFiles.AppendChild($node) | Out-Null
    }

    $config.Configuration.AppendChild($configFiles) | Out-Null
       
    #endregion

    #Don't save the configuration file if -WhatIf is present
    if($PSCmdlet.ShouldProcess($Global:ADFSTKPaths.mainConfigFile,"Create"))
    {
        try 
        {
            $config.Save($Global:ADFSTKPaths.mainConfigFile)
            Write-ADFSTkLog (Get-ADFSTkLanguageText  mainconfNewConfFileCreated -f $Global:ADFSTKPaths.mainConfigFile) -ForegroundColor Green
        }
        catch
        {
            throw $_
        }
    }

    if ($PSBoundParameters.ContainsKey('Passthru'))
    {
        return $config.configuration
    }
}
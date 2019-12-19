function Get-ADFSTkMainConfiguration {

    $ADFSTKPaths = Get-ADFSTKPaths
    
    if(!(Test-Path $ADFSTKPaths.mainConfigFile))
    {
        Write-ADFSTkLog "No ADFSTk main configuration file found!" -MajorFault
    }
    
    try 
    {
        [xml]$config = Get-Content $ADFSTKPaths.mainConfigFile
    }
    catch
    {
        Write-ADFSTkLog "Could not open or parse the ADFSTk main configuration file!`r`n$_" -MajorFault
    }

    $config.Configuration.ConfigFiles.ConfigFile | % {
        $ConfigItems = @()
    }{
        $ConfigItems += New-Object -TypeName PSCustomObject -Property @{
            ConfigFile = $_.'#text'
            Enabled = $_.enabled
        }
    }{
        $ConfigItems
    }
}
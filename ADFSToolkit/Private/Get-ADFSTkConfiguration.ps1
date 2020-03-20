function Get-ADFSTkConfiguration {
param(
    [switch]$ConfigFilesOnly
)

    if ([string]::IsNullOrEmpty($Global:ADFSTkPaths))
    {
        $Global:ADFSTkPaths = Get-ADFSTKPaths
    }
    
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

    if ($PSBoundParameters.ContainsKey('ConfigFilesOnly'))
    {
        if ([string]::IsNullOrEmpty($config.Configuration.ConfigFiles))
        {
            @()
        }
        else
        {
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
    }
    else
    {
        $config.Configuration
    }
}
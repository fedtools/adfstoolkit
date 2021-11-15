function Get-ADFSTkConfiguration {
param(
    [switch]$ConfigFilesOnly
)

    if(!(Test-Path $Global:ADFSTKPaths.mainConfigFile))
    {
        Write-ADFSTkLog (Get-ADFSTkLanguageText mainconfNoConfigFileFound) -MajorFault
    }
    
    try 
    {
        [xml]$config = Get-Content $Global:ADFSTKPaths.mainConfigFile
    }
    catch
    {
        Write-ADFSTkLog (Get-ADFSTkLanguageText mainconfCouldNotParseConfigFile -f $_) -MajorFault
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
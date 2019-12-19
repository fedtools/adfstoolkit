function Get-ADFSTKPaths
{
    $paths = @{}
    $paths.mainDir = 'C:\ADFSToolkit'
    $paths.mainConfigDir = Join-Path $paths.MainDir 'config'
    $paths.mainConfigFile = Join-Path $paths.MainConfigDir 'config.ADFSTk.xml'
    
    $paths.cacheDir = Join-Path $paths.MainConfigDir 'cache'
    
    $paths.institutionDir = Join-Path $paths.MainDir 'institution'

    $paths.federationDir = Join-Path $paths.mainConfigDir 'federation'
    $paths.federationsFile = Join-Path $paths.federationDir 'federations.xml'

    $paths.modulePath = Get-Module -ListAvailable ADFSToolkit | Sort-Object Version -Descending | Select -First 1 | Select -ExpandProperty ModuleBase
    $paths.moduleConfigDir = Join-Path $paths.modulePath 'config'
    $paths.moduleConfigDefaultDir = Join-Path $paths.moduleConfigDir 'default'

    $paths.defaultConfigFile = Join-Path $paths.moduleConfigDefaultDir 'en-US\config.ADFSTk.default_en.xml'
    #$paths.defaultConfigFile = Join-Path $paths.modulePath 'config\default\config.ADFSTk.default.xml' #Next version with language support

    return $paths
}
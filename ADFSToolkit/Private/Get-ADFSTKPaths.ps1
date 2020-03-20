function Get-ADFSTKPaths
{
    $paths = @{}
    $paths.mainDir = 'C:\ADFSToolkit'
    
    $paths.mainConfigDir = Join-Path $paths.MainDir 'config'
    $paths.mainConfigFile = Join-Path $paths.MainConfigDir 'config.ADFSTk.xml'    
    $paths.mainBackupDir = Join-Path $paths.MainConfigDir 'backup'
    
    $paths.cacheDir = Join-Path $paths.MainDir 'cache'
    
    $paths.institutionDir = Join-Path $paths.MainConfigDir 'institution'
    $paths.institutionBackupDir = Join-Path $paths.institutionDir 'backup'

    $paths.federationDir = Join-Path $paths.MainConfigDir 'federation'
    $paths.federationsFile = Join-Path $paths.federationDir 'federations.xml'

    $paths.modulePath = Get-Module -ListAvailable ADFSToolkit | Sort-Object Version -Descending | Select -First 1 | Select -ExpandProperty ModuleBase
    $paths.moduleConfigDir = Join-Path $paths.modulePath 'config'
    $paths.moduleConfigDefaultDir = Join-Path $paths.moduleConfigDir 'default'

    $paths.defaultConfigFile = Join-Path $paths.moduleConfigDefaultDir 'config.ADFSTk.default.xml'
    $paths.defaultInstitutionLocalSPFile = Join-Path $paths.moduleConfigDefaultDir 'get-ADFSTkLocalManualSPSettings-dist.ps1'
    #$paths.defaultConfigFile = Join-Path $paths.modulePath 'config\default\config.ADFSTk.default.xml' #Next version with language support

    return $paths
}
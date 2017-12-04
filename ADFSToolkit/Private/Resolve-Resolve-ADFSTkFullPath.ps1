# based off of http://mnaoumov.wordpress.com/2013/08/21/powershell-resolve-path-safe/
function Resolve-ADFSTkFullPath{
    [cmdletbinding()]
    param
    (
        [Parameter(
            Mandatory=$true,
            Position=0,
            ValueFromPipeline=$true)]
        [string] $path
    )
     
    $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($path)
}
function Set-ADFSTkConfigItem {
param (
    $XPath,
    $ExampleValue,
    $DefaultValue
)

    $ConfigPath = Select-Xml -Xml $config -XPath $XPath

    Write-Host -ForegroundColor Yellow "$($ConfigPath.Node.Name)`: " -NoNewline
    Write-Host -ForegroundColor Gray $ConfigPath.Node.'#text' -NoNewline

    if (![string]::IsNullOrEmpty($ExampleValue)) 
    {
        Write-Host -ForegroundColor Gray " (" -NoNewline    
        Write-Host -ForegroundColor Gray $ExampleValue -NoNewline
        Write-Host -ForegroundColor Gray ")" -noNewline
    }
    
    Write-Host -ForegroundColor Gray "."
    
    $text = "Please provide a value for $($ConfigPath.Node.Name)"
    
    if (![string]::IsNullOrEmpty($DefaultValue))
    {
        $text += " ($DefaultValue)" 
    }

    do 
    {
        $inputValue = Read-Host $text

        if ([string]::IsNullOrEmpty($inputValue))
        {
            if (![string]::IsNullOrEmpty($DefaultValue))
            {
                $inputValue = $DefaultValue
            }
            else
            {
                Write-Warning "You have to provide a value."
            }
        }
    }
    until (![string]::IsNullOrEmpty($inputValue))

    $ConfigPath.Node.'#text' = [string]$inputValue
}
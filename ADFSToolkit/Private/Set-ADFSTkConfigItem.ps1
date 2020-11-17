function Set-ADFSTkConfigItem {
param (
    $NewConfig,
    $DefaultConfig,
    $XPath,
    $ExampleValue
)

    $defaultConfigPath = Select-Xml -Xml $DefaultConfig -XPath $XPath
    $newConfigPath = Select-Xml -Xml $NewConfig -XPath $XPath
    
    Write-Host -ForegroundColor Yellow "$($defaultConfigPath.Node.Name)`: " -NoNewline
    Write-ADFSTkHost "defaultConfiguration_$($XPath)" -ForegroundColor Gray -NoNewLine

    $DefaultValue = $defaultConfigPath.Node.InnerText

    if ([string]::IsNullOrEmpty($DefaultValue)) 
    {
       if (![string]::IsNullOrEmpty($ExampleValue))
       {
            Write-Host -ForegroundColor Gray " ($ExampleValue)" -NoNewline
       }
    }
    else
    {
        Write-Host -ForegroundColor Yellow " ($DefaultValue)" -NoNewline
    }
    
    Write-Host -ForegroundColor Gray "."

    do 
    {
        $inputValue = Read-Host (Get-ADFSTkLanguageText cPleaseProvideValueFor -f $defaultConfigPath.Node.Name)

        if ([string]::IsNullOrEmpty($inputValue))
        {
            if (![string]::IsNullOrEmpty($DefaultValue))
            {
                $inputValue = $DefaultValue
            }
            else
            {
                Write-ADFSTkHost cYouHaveToProvideValue -ForegroundColor Yellow
            }
        }
    }
    while ([string]::IsNullOrEmpty($inputValue))

    # strip carriage returns, tabs, newlines from XML variables
    $inputValue = $inputValue -replace "`t|`n|`r",""

    $NewConfigPath.Node.InnerText = [string]$inputValue
}
function Write-ADFSTkHost {
[CmdletBinding(DefaultParameterSetName='TextID')]
param (
    [Parameter(Mandatory=$true, 
               ParameterSetName='TextID', 
               Position=0)]
    $TextID,
    [Parameter(Mandatory=$true, 
               ParameterSetName='PlainText', 
               Position=0)]
    $Text,
    [Parameter(Mandatory=$false, 
               ParameterSetName='TextID')]
    [Parameter(Mandatory=$false, 
               ParameterSetName='PlainText')]
    $f,
    [Parameter(Mandatory=$false, 
               Position=1)]
    [ValidateSet('Black','DarkBlue','DarkGreen','DarkCyan','DarkRed','DarkMagenta','DarkYellow','Gray','DarkGray','Blue','Green','Cyan','Red','Magenta','Yellow','White')]
    $ForegroundColor,
    [Parameter(Mandatory=$false, 
               ParameterSetName='TextID')]
    [Parameter(Mandatory=$false, 
               ParameterSetName='PlainText')]
    [ValidateSet('Info', 'Value', 'Attention', 'Done')]
    $Style,
    [Parameter(Mandatory=$false, 
               ParameterSetName='TextID')]
    [Parameter(Mandatory=$false, 
               ParameterSetName='PlainText')]
    [switch]$NoNewLine,
    [Parameter(Mandatory=$false, 
               ParameterSetName='TextID')]
    [Parameter(Mandatory=$false, 
               ParameterSetName='PlainText')]
    [switch]$AddLinesOverAndUnder,
    [Parameter(ParameterSetName='LineOnly')]
    [switch]$WriteLine,
    [switch]$AddSpaceAfter,
    [switch]$AddSpaceBefore
)

    $Parameters = @{}

    if ($PsCmdlet.ParameterSetName -eq "TextID")
    {
        $Text = Get-ADFSTkLanguageText -TextID $TextID
    }
    elseif ($PSBoundParameters.ContainsKey('WriteLine'))
    {
        $Text = "--------------------------------------------------------------------------------------------------------------"
        $Parameters.ForegroundColor = 'Cyan'
    }
    
    if ($PSBoundParameters.ContainsKey('f'))
    {
        $Text = $Text -f $f
    }

    if ($PSBoundParameters.ContainsKey('Style'))
    {
        switch ($Style)
        {
            'Info' {$Parameters.ForegroundColor = 'Cyan'}
            'Value' {$Parameters.ForegroundColor = 'Gray'}
            'Attention' {$Parameters.ForegroundColor = 'Yellow'}
            'Done' {$Parameters.ForegroundColor = 'Green'}
        }
    }

    if ($PSBoundParameters.ContainsKey('ForegroundColor'))
    {
        $Parameters.ForegroundColor = $ForegroundColor
    }

    if ($PSBoundParameters.ContainsKey('NoNewLine') -and -not $PSBoundParameters.ContainsKey('AddLinesOverAndUnder'))
    {
        $Parameters.NoNewLine = $true
    }

    if ($PSBoundParameters.ContainsKey('AddSpaceBefore'))
    {
        Write-Host " "
    }

    if ($PSBoundParameters.ContainsKey('AddLinesOverAndUnder'))
    {
        Write-Host "--------------------------------------------------------------------------------------------------------------`r`n" @Parameters
    }

    Write-Host $Text @Parameters

    if ($PSBoundParameters.ContainsKey('AddLinesOverAndUnder'))
    {
        Write-Host "`r`n--------------------------------------------------------------------------------------------------------------" @Parameters
    }

    if ($PSBoundParameters.ContainsKey('AddSpaceAfter'))
    {
        Write-Host " "
    }
}
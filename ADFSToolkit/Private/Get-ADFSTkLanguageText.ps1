function Get-ADFSTkLanguageText {
param (
    [Parameter(Mandatory=$true, Position=0)]
    $TextID,
    [Parameter(Mandatory=$false, Position=1)]
    $Language,
    $f
)

    $languageFileName = "ADFSTk_{0}.pson"
    $selectedLanguage = $null

    if ($PSBoundParameters.ContainsKey('Language'))
    {
        $selectedLanguage = $Language
    }
    #selectedLanguage is a global variable that holds the current selected language
    #chosen by user. The value should be the language code i.e. en-US
    elseif ([string]::IsNullOrEmpty($Global:ADFSTkSelectedLanguage))
    {
        $selectedLanguage = $null
        #We need to be able to proceed without a ADFSTk Config file
        if (Test-Path ($Global:ADFSTkPaths.mainConfigFile))
        {
            try 
            {
                [xml]$config = Get-Content $Global:ADFSTKPaths.mainConfigFile
                $selectedLanguage = $config.Configuration.OutputLanguage
            }
            catch
            {
                
            }
        }

        if ([string]::IsNullOrEmpty($selectedLanguage))
        {
            $languagePacks = Join-Path $Global:ADFSTKPaths.modulePath "languagePacks" 

            #Get all directories that contains a language file with the right name
            $possibleLanguageDirs = Get-ChildItem $languagePacks -Directory | ? {Test-Path (Join-Path $_.FullName ($languageFileName -f $_.Name))}

            #Filter out the directories that doesn't have a correct name
            $configFoundLanguages = (Compare-ADFSTkObject -FirstSet $possibleLanguageDirs.Name `
                                                                -SecondSet ([System.Globalization.CultureInfo]::GetCultures("SpecificCultures").Name) `
                                                                -CompareType Intersection).CompareSet
    
            $configFoundLanguages | % {
                $choices = @()
                $caption = "Select language"
                $message = "Please select which language you want help text in."
                $defaultChoice = 0
                $result = 0
                $i = 0
            }{
                $choices += New-Object System.Management.Automation.Host.ChoiceDescription "&$([System.Globalization.CultureInfo]::GetCultureInfo($_).DisplayName)","" #if we want more than one language with the same starting letter we need to redo this (number the languages)
                if ($_ -eq "en-US") {
                    $defaultChoice = $i
                }
                $i++
            }{
            
                if ($choices.count -ne 1) #If only one choice, no need to ask. $result will be 0 which is the only option
                {
                    $result = $Host.UI.PromptForChoice($caption,$message,[System.Management.Automation.Host.ChoiceDescription[]]$choices,$defaultChoice) 
                }
            }

            if ($result -eq -1)
            {
                #If the user clicks cancel/X
                $selectedLanguage = 'en-US'
            }
            else
            {
                $selectedLanguage = ([string[]]$configFoundLanguages)[$result]
            }

            $Global:ADFSTkSelectedLanguage = $selectedLanguage

            Set-ADFSTkConfiguration -OutputLanguage $selectedLanguage
        }
        else
        {
            #$selectedLanguage = $Configuration.OutputLanguage
            $Global:ADFSTkSelectedLanguage = $selectedLanguage
        }
    }
    else
    {
        $selectedLanguage = $Global:ADFSTkSelectedLanguage
    }

    #LanguageTables is a global variable that contains one or more language table.
    #The key is the language code i.e. en-US and the value is a hash table read from
    #a language file. 
    if ([string]::IsNullOrEmpty($Global:ADFSTkLanguageTables))
    {
        $Global:ADFSTkLanguageTables = @{}
    }

    if (!$Global:ADFSTkLanguageTables.ContainsKey($selectedLanguage))
    {
        $languagePacks = Join-Path $Global:ADFSTKPaths.modulePath "languagePacks" 

        $languageDir = Join-Path $languagePacks $selectedLanguage
        $languageFile = Join-Path $languageDir ($languageFileName -f $selectedLanguage)

        if (!(Test-Path $languageFile))
        {
            Write-ADFSTkLog "Requested language not available!" -MajorFault
        }

        try {
            $languageContent = Get-Content $languageFile | Out-String
            $languageData = Invoke-Expression $languageContent
        }
        catch {
            Write-ADFSTkLog "Could not open language file!" -MajorFault
        }

        $Global:ADFSTkLanguageTables.$selectedLanguage = $languageData
    }

    if ($PSBoundParameters.ContainsKey('f'))
    {
        if ($Global:ADFSTkLanguageTables.$selectedLanguage.ContainsKey($TextID))
        {
            return $Global:ADFSTkLanguageTables.$selectedLanguage.$TextID -f $f
        }
        elseif($selectedLanguage -ne "en-US")
        {
            #Log an warning
            Write-ADFSTkVerboseLog "The languageID: '$TextID' could not be found in '$selectedLanguage'. We will try to find it in 'en-US'"
            return Get-ADFSTkLanguageText $TextID -f $f -Language 'en-US'
        }
        else
        {
            #at least log an error
            return "[ErrorLanguageStringNotFound: $TextID]"
        }
    }
    else
    {
        if ($Global:ADFSTkLanguageTables.$selectedLanguage.ContainsKey($TextID))
        {
            return $Global:ADFSTkLanguageTables.$selectedLanguage.$TextID
        }
        elseif($selectedLanguage -ne "en-US")
        {
            #Log an warning
            Write-ADFSTkVerboseLog "The languageID: '$TextID' could not be found in '$selectedLanguage'. We will try to find it in 'en-US'"
            return Get-ADFSTkLanguageText $TextID -Language 'en-US'
        }
        else
        {
            #at least log an error 
            #return string 
            return "[ErrorLanguageStringNotFound: $TextID]"
        }
    }
        
}


function Get-ADFSTkMFAAdapter {
    

    $authProviders = Get-AdfsAuthenticationProvider

    $nameMFA = "RefedsMFAUsernamePasswordAdapter"
    $nameSFA = "RefedsSFAUsernamePasswordAdapter"
    
    if ($authProviders.Name.Contains($nameMFA)) {
        Write-ADFSTkHost mfaAdapterPresent -f 'RefedsMFA','IS' -ForegroundColor Green
    }
    else {
        Write-ADFSTkHost mfaAdapterPresent -f 'RefedsMFA','IS NOT' -ForegroundColor Red
    }
    
    if ($authProviders.Name.Contains($nameSFA)) {
        Write-ADFSTkHost mfaAdapterPresent -f 'RefedsSFA','IS' -ForegroundColor Green
    }
    else {
        Write-ADFSTkHost mfaAdapterPresent -f 'RefedsSFA','IS NOT' -ForegroundColor Red
    }
}
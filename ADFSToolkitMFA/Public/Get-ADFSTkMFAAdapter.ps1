

function Get-ADFSTkMFAAdapter {
    

    $authProviders = Get-AdfsAuthenticationProvider

    $nameMFA = "RefedsMFAUsernamePasswordAdapter"
    $nameSFA = "RefedsSFAUsernamePasswordAdapter"
    
    if ($authProviders.Name.Contains($nameMFA)) {
        Write-ADFSTkHost "RefedsMFA Adapter IS present!" -ForegroundColor Green
    }
    else {
        Write-ADFSTkHost "RefedsMFA Adapter IS NOT present!" -ForegroundColor Red
    }
    
    if ($authProviders.Name.Contains($nameSFA)) {
        Write-ADFSTkHost "RefedsSFA Adapter IS present!" -ForegroundColor Green
    }
    else {
        Write-ADFSTkHost "RefedsSFA Adapter IS NOT present!" -ForegroundColor Red
    }
}
###
## Coinbase Pro API Authentication Headers Module
###

##
# Set API credentials
function Set-Credentials {
    param(
        [Parameter(Mandatory=$true)]$Key,
        [Parameter(Mandatory=$true)]$Passphrase,
        [Parameter(Mandatory=$true)]$Secret
    )

    # Key by Coinbase Pro, should have some kind of structure
    $Script:key = $Key

    # Passphrase entered is user input, so no validation, length > 0
    $Script:passphrase = $Passphrase

    # Secret by Coinbase Pro, is base64 decodable
    $Script:secret = $Secret

    # check if the credentials are set correctly
    Get-Credentials | out-null
}


##
# Generate API Headers for 'private' requests
function Get-Headers {
    param(
        [Parameter(Mandatory=$true)] $method,
        [Parameter(Mandatory=$true)] $path,
        [Parameter(Mandatory=$false)]$body = ''
    )

    # get coinbase pro credentials
    $cred = Get-Credentials

    # get unix timestamp of now
    $timestamp = Get-Date -Date (Get-Date).ToUniversalTime() -Millisecond 0 -UFormat %s
    
    # generate the composed signature
    $sign = $timestamp , $method.ToUpper() , $path , $body -join ''
    
    # hmac it
    $signHMAC = ConvertTo-HMAC -message $sign -secret ([Convert]::FromBase64String($cred.secret))
    
    # encode the signing string
    $signBase64 = [Convert]::ToBase64String($signHMAC)
    
    return @{
        'CB-ACCESS-KEY' = $cred.key;
        'CB-ACCESS-PASSPHRASE' = $cred.passphrase;
        'CB-ACCESS-SIGN' = $signBase64;
        'CB-ACCESS-TIMESTAMP' = $timestamp;
        'Content-Type' = 'application/json';
    }
}


function ConvertTo-HMAC {
    param(
        [Parameter(Mandatory=$true)]$message,
        [Parameter(Mandatory=$true)]$secret
    )

    $hmacsha = New-Object System.Security.Cryptography.HMACSHA256
    $hmacsha.key = $secret
    
    return $hmacsha.ComputeHash([Text.Encoding]::ASCII.GetBytes($message))
}


Function Get-Credentials {
    # check required properties
    if( $Script:key.length -lt 1 -or
        $Script:passphrase.length -lt 1 -or
        $Script:secret.length -lt 1 ){
            throw 'No Credentials are set. use Set-CBPROCredentials'
    }

    return @{
        'key' = $Script:key;
        'passphrase' = $Script:passphrase;
        'secret' = $Script:secret;
    }
}



Export-ModuleMember Get-Headers, Set-Credentials
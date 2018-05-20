###
## GDAX API Module
###


##
# Set GDAX Endpoint Envoironment
#  @param environment string live or sandbox
#  This function must be executed in order to have the API endpoint set
function Set-Environment {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("live", "sandbox")]
        [String]$environment)

    $Script:environment = $environment.toLower()
    
    switch($Script:environment){
        "live"{
            $Script:uri = 'https://api.gdax.com'
        }
        "sandbox"{
            $Script:uri = 'https://api-public.sandbox.gdax.com'
        }
    }
}


##
# Get GDAX API Endpoint
function Get-Endpoint {
    if( $Script:uri.Length -lt 1 ){
        throw "No GDAX Environment set. (call Set-GDAXEnvironment to set one)"
    }

    return $Script:uri
}


##
# Invoke a call to the GDAX API
Function Invoke-Endpoint {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('GET','POST','DELETE')]$Method,
        [String]$Path = '',
        [String]$Body = '',
        [Switch]$Private
    )

    # make sure the path starts with a forward slash
    if( $Path.Length -gt 0 -and -not $Path.StartsWith('/') ){
        $Path = '/' + $Path
    }

    # prepare the parameters for invoking the api
    $invokeParams = @{
        'Method' = $Method;
        'Uri' = ((Get-Endpoint) + $Path);
    }

    # check for Body contents
    if( $Body.Length -gt 0 -and $Method -in 'POST' ){
        # and set it if applicable
        $invokeParams.Add('Body', $Body)
    }

    # if it is a private endpoint, get some authentication going
    if( $Private ){
        # load authentication module
        Get-Module gdax-auth | Out-Null

        # set authentication headers
        $invokeParams.Add('Headers', (get-GDAXHeaders -method $Method -path $Path -body $Body))
    }

    return Invoke-RestMethod @invokeParams
}



Export-ModuleMember Set-Environment, Get-Endpoint, Invoke-Endpoint
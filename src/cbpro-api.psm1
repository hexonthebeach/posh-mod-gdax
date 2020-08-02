###
## Coinbase pro API Module
###


##
# Set Coinbase Pro Endpoint Envoironment
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
            $Script:uri = 'https://api.pro.coinbase.com'
        }
        "sandbox"{
            $Script:uri = 'https://api-public.sandbox.pro.coinbase.com'
        }
    }
}


##
# Get Coinbase Pro API Endpoint
function Get-Endpoint {
    if( $Script:uri.Length -lt 1 ){
        throw "No Coinabse Pro Environment set. (call Set-CBPROEnvironment to set one)"
    }

    return $Script:uri
}


##
# Invoke a call to the Coinbase Pro API
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
        'Uri' = ((Get-CBPROEndpoint) + $Path);
    }

    # check for Body contents
    if( $Body.Length -gt 0 -and $Method -in 'POST' ){
        # and set it if applicable
        $invokeParams.Add('Body', $Body)
    }

    # if it is a private endpoint, get some authentication going
    if( $Private ){
        # load authentication module
        Get-Module cbpro-auth | Out-Null

        # set authentication headers
        $invokeParams.Add('Headers', (get-CBPROHeaders -method $Method -path $Path -body $Body))
    }

    return Invoke-RestMethod @invokeParams
}



Export-ModuleMember Set-Environment, Get-Endpoint, Invoke-Endpoint
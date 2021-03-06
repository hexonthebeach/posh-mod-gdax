###
## Coinbase Pro API Users Module
###

$Script:base = '/users'

<#
 .Synopsis
  Get User details

 .Description
  Read the User details from the Coinbase Pro API
#>
Function Get-Self {
    
    $path = $Script:base,'self' -join '/'

    return Invoke-CBPROEndpoint -Method Get -Path $path -Private
}


<#
 .Synopsis
  Get Volume of trades last 30 days

 .Description
  Reads the total Volume of trades per product, this value is calculated once a day and cached
#>
Function Get-TrailingVolume {

    $path =$Script:base,'self','trailing-volume' -join '/'

    return Invoke-CBPROEndpoint -Method Get -Path $path -Private
}

Export-ModuleMember Get-Self, Get-TrailingVolume
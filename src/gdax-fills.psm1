###
## GDAX API Fills Module
###

$Script:base = '/fills'


##
# Get a list of recent Fills
#  filter by Product ID
#  optionaly Before order id to get only newer fills
Function Get-Fills {
    param(
        [Parameter(Mandatory=$true)]
        $Product,
        [Parameter(Mandatory=$false)]
        $Before
    )

    $endpoint = $Script:base + "?product_id=" + $Product

    if( $Before ){
        $endpoint += "&order_id=" + $Before
    }

    return Invoke-GDAXEndpoint -Method Get -Path $endpoint
}


Export-ModuleMember Get-Fills
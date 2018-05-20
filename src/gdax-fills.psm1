###
## GDAX API Fills Module
###

$Script:base = '/fills'


<#
 .Synopsis
  Gets a list of recent Fills.

 .Description
  Calls the GDAX API Private endpoint to fetch a list of recent Fills.

 .Parameter ProductID
  A ProductID to filter the list of Fills
  
 .Parameter OrderID
  An OrderID to filter the list of Fills

 .Parameter Before
  A TradeID to filter out all Fills from before that trade
#>
Function Get-Fills {
    param(
        [Parameter(Mandatory=$false)]
        $ProductID,
        [Parameter(Mandatory=$false)]
        $OrderID,
        [Parameter(Mandatory=$false)]
        $Before
    )

    # set the endpoint
    $endpoint = $Script:base

    # set the concatinator
    $c = '?'

    if( $MyInvocation.BoundParameters.ContainsKey('ProductID') ){
        # add product_id param
        $endpoint += $c + "product_id=" + $ProductID

        # change concatinator
        $c = '&'
    }

    if( $MyInvocation.BoundParameters.ContainsKey('OrderID') ){
        # add order_id param
        $endpoint += $c + "order_id=" + $OrderID

        # change concatinator
        $c = '&'
    }

    if( $MyInvocation.BoundParameters.ContainsKey('Before') ){
        # add the trade_id param
        $endpoint += $c + "trade_id=" + $Before
    }

    return Invoke-GDAXEndpoint -Method Get -Path $endpoint -Private
}


Export-ModuleMember Get-Fills
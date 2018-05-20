###
## GDAX API Orders Module
###

$Script:base = '/orders'


##
# List Your Orders
#  Product identifier
#  Status returns all not-settled orders by default
Function Get-Orders {
    param(
        [Parameter(Mandatory=$false)]
        [String]
        $ProductID,
        [Parameter(Mandatory=$false)]
        [ValidateSet('active','all','open','pending')]
        $Status
    )

    $path = $Script:base

    if( $ProductID -or $Status ){
        $path += '?'
    }

    if( $ProductID ){ $path += 'product_id=' + $ProductID }

    if( $Status ){ $path += 'status=' + $Status }

    return Invoke-GDAXEndpoint -Private -Method Get -Path $path
}


##
# Get a single Order by ID
Function Get-Order {
    param(
        [Parameter(Mandatory=$true)]
        $ID
    )

    $path = $Script:base,$ID -join '/'

    return Invoke-GDAXEndpoint -Private -Method Get -Path $path
}


##
# Cancel ALL Of Your Orders
#  optional Product parameter to only Cancel orders for a specific Product
Function Remove-Orders {
    param(
        [Parameter(Mandatory=$false)]
        $Product
    )

    $path = $Script:base

    if( $Product ){
        $path += '?product_id=' + $Product
    }

    return Invoke-GDAXEndpoint -Private -Method Delete -Path $path
}


##
# Cancel a single Order
Function Remove-Order {
    param(
        [Parameter(Mandatory=$true)]
        $ID
    )

    $path = $Script:base,$ID -join '/'

    Invoke-GDAXEndpoint -Private -Method Delete -Path $path
}


##
# Place a new Order
#  this function supports all possible parameters used in Limit and Market orders
#  using New-LimitOrder or New-MarketOrder might be more readable in code
Function New-Order {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('buy','sell')]
        $Side,
        [Parameter(Mandatory=$true)]
        $ProductID,
        [Parameter(Mandatory=$true)]
        [ValidateSet('limit','market')]
        $Type,

        [Parameter(Mandatory=$false)]
        [ValidateSet('dc','co','cn','cb')] # DecreaseAndCacnel,CancelOldest,CancelNewest,CancelBoth
        $SelfTradePrevention = 'dc',
        [Parameter(Mandatory=$false)]
        [ValidateSet('loss','entry')]
        [String]$Stop,
        [Parameter(Mandatory=$false)]
        [Double]$StopPrice,
        
        [Parameter(Mandatory=$false)]
        $ClientOrderID, # = ([guid]::NewGuid()).ToString(),
        
        [Parameter(Mandatory=$false)]
        [Double]$Size,
        [Parameter(Mandatory=$false)]
        [Double]$Funds,

        [Parameter(Mandatory=$false)]
        [Double]$Price,
        [Parameter(Mandatory=$false)]
        [ValidateSet('GTC','GTT','IOC','FOK')]
        $TimeInForce = 'GTC',
        [Parameter(Mandatory=$false)]
        [ValidateSet('min','hour','day')]
        $CancelAfter,
        [Parameter(Mandatory=$false)]
        $PostOnly,

        [Parameter(Mandatory=$false)]
        [Switch]$Place
    )

    # set the properties that apply to both Limit and Market Orders
    $order = @{
        'type' = $Type;
        'side' = $Side;
        'product_id' = $ProductID;
    }

    # set self trade prevention if one is provided
    if( $SelfTradePrevention ){
        $order.Add('stp', $SelfTradePrevention);
    }

    # stop and stop_price must go together
    if( $Stop.Length -gt 0 -and $StopPrice -gt 0 ){
        $order.Add('stop', $Stop)
        $order.Add('stop_price', $StopPrice)
    }

    # add a client order id if it is provided
    if( $MyInvocation.BoundParameters.ContainsKey('ClientOrderID') ){
        $order.Add('client_oid', $ClientOrderID)
    }


    # limit order needs a specific set or parameters
    if( $Type -eq 'limit' ){
        # this set to be precise
        $limitParams = @{}
        # maybe more, see which one of these are provided
        'Price','Size','TimeInForce','CancelAfter','PostOnly' |ForEach-Object{
            if ( $MyInvocation.BoundParameters.ContainsKey($_) ) {
                $limitParams.Add($_ , $MyInvocation.BoundParameters.Item($_) )
            }
        }

        # check validity and add if no error is thrown
        $order += (New-LimitOrder @limitParams)
    }

    # market order needs another set of specific parameters, obviously
    if( $Type -eq 'market' ){
        # this set to be precise
        $marketParams = @{}
        # maybe one of these as well
        'Funds','Size' |ForEach-Object{
            if ( $MyInvocation.BoundParameters.ContainsKey($_) ) {
                $marketParams.Add($_ , $MyInvocation.BoundParameters.Item($_) )
            }
        }

        # check validity and add if no error is thrown
        $order += (New-MarketOrder @marketParams)
    }

    


    if($Place){
        return Invoke-Order $order
    }else{
        return $order
    }
}


##
# Place a new Order of Limit type
#  
Function New-LimitOrder {
    param(
        [Parameter(Mandatory=$true)]
        $Price,
        [Parameter(Mandatory=$true)]
        $Size,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('GTC','GTT','IOC','FOK')] # GoodTilCancel,GoodTillTime,ImmediateOrCancel,FillOrKill
        $TimeInForce = 'GTC',
        [Parameter(Mandatory=$false)]
        [ValidateSet('min','hour','day')]
        $CancelAfter,
        [Parameter(Mandatory=$false)]
        $PostOnly
    )

    # CancelAfter requires TimeInForce to be GTT
    if( $MyInvocation.BoundParameters.ContainsKey('CancelAfter') -and $TimeInForce -ne 'GTT' ){
        throw 'CancelAfter requires TimeInForce to be GTT'
    }

    # PostOnly is not allowed together with IOC or FOK
    if( $MyInvocation.BoundParameters.ContainsKey('PostOnly') -and $TimeInForce -in 'IOC','FOK' ){
        throw 'PostOnly is not allowed with TimeInForce set to IOC or FOK'
    }


    # Price and Size are Mandatory
    $return = @{
        'price' = [math]::Round($Price, 2);
        'size' = [math]::Round($Size, 2);
    }

    # add the time in force
    if( $MyInvocation.BoundParameters.ContainsKey('TimeInForce') ){
        $return.Add('time_in_force', $TimeInForce)
    }
    
    # add the cancel after
    if( $MyInvocation.BoundParameters.ContainsKey('CancelAfter') ){
        $return.Add('cancel_after', $CancelAfter)
    }
    
    # add the post_only
    if( $MyInvocation.BoundParameters.ContainsKey('PostOnly') ){
        $return.Add('post_only', $PostOnly)
    }


    return [Hashtable]$return
}


##
# Place a new Order of Market type
#  they have NO pricing guarantee
#   will execute instantly
#   will not eppear in Order Books
#   will always be charged a Takers' fee
Function New-MarketOrder {
    param(
        [Parameter(Mandatory=$false)]
        [Double]$Funds,
        [Parameter(Mandatory=$false)]
        [Double]$Size
    )

    # at least one of Funds or Size must be set
    if( $MyInvocation.BoundParameters.Count -lt 1 ){
        throw 'Market Order needs at least one of Funds or Size parameters'
    }

    # lowercase the property names so the are good to go
    $return = @{}
    if( $MyInvocation.BoundParameters.ContainsKey('Funds') ){
        $return.Add('funds', $Funds)
    }
    if( $MyInvocation.BoundParameters.ContainsKey('Size') ){
        $return.Add('size', $Size)
    }

    return [hashtable]$return
}


##
# Place the provided Order object
Function Invoke-Order {
    param(
        [Parameter(Mandatory=$true)]
        $Order
    )

    return (Invoke-GDAXEndpoint -Private -Method Post -Path $Script:base -Body ($Order |ConvertTo-Json))
}


##
# Find the Fee percentage for an order
Function Find-Fee {

    # TODO: incorporate a quick fiat-Volume lookup
    $volume = 1000

    switch($volume){
        # under 10 M
        ($volume -lt 10.000.000) {
            return 0.3
        }

        # over 100 M
        ($volume -ge 100.000.000) {
            return 0.1
        }

        # between 10 M and 100 M
        default {
            return 0.2
        }
    }
}

Export-ModuleMember Get-Orders, Get-Order, Remove-Orders, Remove-Order, New-Order, Find-Fee
###
## Coinbase Pro API Orders Module
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

    $glue = '?'

    if( $MyInvocation.BoundParameters.ContainsKey('ProductID') ){
        $path += $glue + 'product_id=' + $ProductID

        $glue = '&'
    }

    if( $MyInvocation.BoundParameters.ContainsKey('Status') ){
        $path += $glue + 'status=' + $Status
    }

    return Invoke-CBPROEndpoint -Private -Method Get -Path $path
}


##
# Get a single Order by ID
Function Get-Order {
    param(
        [Parameter(Mandatory=$true)]
        $ID
    )

    $path = $Script:base,$ID -join '/'

    return Invoke-CBPROEndpoint -Private -Method Get -Path $path
}


##
# Cancel ALL Your Orders
#  optional Product parameter to only Cancel orders for a specific Product
Function Remove-Orders {
    param(
        [Parameter(Mandatory=$false)]
        $ProductID
    )

    $path = $Script:base

    if( $MyInvocation.BoundParameters.ContainsKey('ProductID') ){
        $path += '?product_id=' + $ProductID
    }

    return Invoke-CBPROEndpoint -Private -Method Delete -Path $path
}


##
# Cancel a single Order
Function Remove-Order {
    param(
        [Parameter(Mandatory=$true)]
        $ID
    )

    $path = $Script:base,$ID -join '/'

    Invoke-CBPROEndpoint -Private -Method Delete -Path $path
}


##
# Place a new Order
#  this function supports all possible parameters used in Limit and Market orders
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

    # set self trade prevention, dc if none is provided
    $order.Add('stp', $SelfTradePrevention);
    
    # stop and stop_price must go together
    if( $MyInvocation.BoundParameters.ContainsKey('Stop') -and $MyInvocation.BoundParameters.ContainsKey('StopPrice') ){
        $order.Add('stop', $Stop)
        $order.Add('stop_price', $StopPrice)
    }

    # add a client order id if it is provided
    if( $MyInvocation.BoundParameters.ContainsKey('ClientOrderID') ){
        $order.Add('client_oid', $ClientOrderID)
    }


    $orderParams = @{}
    # process one Type
    switch ($Type) {
        # limit order needs a specific set or parameters
        'limit' {
            # this set to be precise
            'Price','Size','TimeInForce','CancelAfter','PostOnly' |ForEach-Object{
                if ( $MyInvocation.BoundParameters.ContainsKey($_) ) {
                    $orderParams.Add($_ , $MyInvocation.BoundParameters.Item($_) )
                }
            }

            # check validity and add Limit order properties if no error is thrown
            $order += (New-LimitOrder @orderParams)
        }

        # market order needs another set of specific parameters, obviously
        'market' {
            # this set to be precise
            'Funds','Size' |ForEach-Object{
                if ( $MyInvocation.BoundParameters.ContainsKey($_) ) {
                    $orderParams.Add($_ , $MyInvocation.BoundParameters.Item($_) )
                }
            }

            # check validity and add Market order properties if no error is thrown
            $order += (New-MarketOrder @orderParams)
        }
    }


    if($Place){
        return Invoke-CBPROOrder $order
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
#   will not appear in Order Books
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

    # lowercase the property names so they are good to go
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
# Place the provided Order
Function Invoke-Order {
    param(
        [Parameter(Mandatory=$true)]
        $Order
    )

    return (Invoke-CBPROEndpoint -Private -Method Post -Path $Script:base -Body ($Order |ConvertTo-Json))
}


##
# Find the Fee percentage for an order
Function Find-Fee {
    param(
        [Parameter(Mandatory=$true)]
        $ProductID
    )

    try{
        $fees = Invoke-CBPROEndpoint -Method GET -Path "fees" -Private

        # return the highest of the two to be on the safe side
        return [Math]::Max($fees.maker_fee_rate, $fees.taker_fee_rate)
    }catch{
        # return 1% in case of emergency
        return 0.01
    }
}

Export-ModuleMember Get-Orders, Get-Order, Remove-Orders, Remove-Order, New-Order, Invoke-Order, Find-Fee
###
## GDAX API Products Module
###

$Script:base = '/products'


##
# list products
function Get-Products {
    return Invoke-GDAXEndpoint -Method Get -Path ($Script:base)
}


##
# list open orders
function Get-ProductBook {
    param(
            [Parameter(Mandatory=$true)]$ProductID,
            [Parameter(Mandatory=$false)]$Level = 1
        )
    
    $endpoint = $Script:base,$ProductID,'book' -join '/'
    
    return Invoke-GDAXEndpoint -Method Get -Path $endpoint
}


##
# last trade/tick, best bid/ask and 24h volume
function Get-ProductTicker {
    param(
            [Parameter(Mandatory=$true)]$ProductID
        )
    
    $endpoint = $Script:base,$ProductID,'ticker' -join '/'
    
    return Invoke-GDAXEndpoint -Method Get -Path $endpoint
}


##
# list last trades
function Get-ProductTrades {
    param(
            [Parameter(Mandatory=$true)]$ProductID
        )
    
    $endpoint = $Script:base,$ProductID,'trades' -join '/'
    
    return Invoke-GDAXEndpoint -Method Get -Path $endpoint
}


##
# list historic rates
# ordered ascending by timestamp so you can get '-last 10' intuitively
function Get-ProductCandles {
    param(
            [Parameter(Mandatory=$true)]$ProductID,
            [Parameter(Mandatory=$false)]$Start,
            [Parameter(Mandatory=$false)]$End,
            [Parameter(Mandatory=$false)][ValidateSet(60,300,900,3600,21600,86400)]$Granularity = 60
        )

    $endpoint = $Script:base,$ProductID,'candles' -join '/'

    $endpoint += '?granularity=' + $Granularity
    
    $candles = Invoke-GDAXEndpoint -Method Get -Path $endpoint

    $return = $candles |ForEach-Object{ New-CandleObject -Candle $_ }

    return $return |Sort-Object timestamp
}


##
# make beautiful candle babies
#  for use by the PoductCandles function
function New-CandleObject {
    param([Parameter(Mandatory=$true)]$Candle)

    $utc = (Get-Date).ToUniversalTime()
    $secNow = [int][double]::Parse((Get-Date $utc -UFormat %s))

    $dt = Get-Date
    $dt = $dt.AddSeconds($Candle[0] - $secNow)
    
    $o = New-Object System.Object
    
    $o | Add-Member -MemberType NoteProperty -Name timestamp -Value $dt
    $o | Add-Member -MemberType NoteProperty -Name low -Value $Candle[1]
    $o | Add-Member -MemberType NoteProperty -Name high -Value $Candle[2]
    $o | Add-Member -MemberType NoteProperty -Name open -Value $Candle[3]
    $o | Add-Member -MemberType NoteProperty -Name close -Value $Candle[4]
    $o | Add-Member -MemberType NoteProperty -Name volume -Value $Candle[5]
    
    return $o
}



##
# 24 hour statistics
#    volume is in base currency
#    open,high,low are in quote currency
function Get-ProductStats {
    param(
            [Parameter(Mandatory=$true)]$ProductID
        )
    
    $path = $Script:base,$ProductID,'stats' -join '/'
    
    return Invoke-GDAXEndpoint -Method Get -Path $path
}


##
# server time
function Get-Time {
    return Invoke-GDAXEndpoint -Method Get -Path '/time'
}


##
# list currencies
function Get-Currencies {
    return Invoke-GDAXEndpoint -Method GET -Path '/currencies'
}




Export-ModuleMember Get-Products, Get-ProductBook, Get-ProductTicker,Get-ProductTrades, Get-ProductCandles, Get-ProductStats, Get-Time, Get-Currencies
###
## GDAX API Authentication Headers Module
###

$Script:base = '/accounts'


##
# List Accounts
Function Get-Accounts {
    return Invoke-GDAXEndpoint -Private -Method GET -Path ($Script:base)
}


##
# Specific account details
Function Get-Account {
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Account
    )

    $path = $Script:base,$account -join '/'

    return Invoke-GDAXEndpoint -Private -Method GET -Path $path
}


##
# Ledger information for an account
Function Get-AccountHistory {
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Account
    )

    $path = $Script:base,$account,'ledger' -join '/'

    return Invoke-GDAXEndpoint -Private -Method GET -Path $path
}


##
# get Holds information for an account
Function Get-AccountHolds {
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Account
    )

    $path = $Script:base,$account,'holds' -join '/'

    return Invoke-GDAXEndpoint -Private -Method GET -Path $path
}


Export-ModuleMember Get-Accounts, Get-Account, Get-AccountHistory, Get-AccountHolds
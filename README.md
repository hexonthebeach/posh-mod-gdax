# POSH-MOD-GDAX
PowerShell Module collection for Coinbase GDAX interaction

## Why
Simplify the interaction with the GDAX API. Making connecting to it and using it effortless and painless.

## Installation
Clone the project to a directory that can be read by your script.

Any location is fine, but one of these might be useful

Make the modules available to the whole system by putting them here:
``
C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules
``

Make the modules available for a specific account by putting them here:
``
C:\Users\<aSpecificAccount>\Documents\WindowsPowerShell\Modules
``

## How
Use the GDAX prefix when importing the modules, modules with dependencies on eachother rely on this prefix.

- ``gdax-api`` handles calling the API
- ``gdax-auth`` handles Credentials for authentication when nesseccary
- ``gdax-accounts`` shows your Accounts, History and Holds
- ``gdax-fills`` shows your recent Fills
- ``gdax-marketdata`` conatins public information like /products /currencies and /time
- ``gdax-orders`` handles all your Order mutations, creating listing and cancelling them

```
Import-Module gdax-api.psm1 -Prefix GDAX -Force
Import-Module gdax-auth.psm1 -Prefix GDAX -Force
Import-Module gdax-accounts.psm1 -Prefix GDAX -Force
Import-Module gdax-fills.psm1 -Prefix GDAX -Force
Import-Module gdax-marketdata.psm1 -Prefix GDAX -Force
Import-Module gdax-orders.psm1 -Prefix GDAX -Force

# set the environment to use
Set-GDAXEnvironment "sandbox"
# supply credentials
Set-GDAXCredentials -Key 'thekeystring' -Passphrase 'thepassphrasestring' -Secret 'thebase64encodedsecret'

# list your accounts
$accounts = Get-GDAXAccounts
$accounts |Format-Table -AutoSize

# get the latest trade to see the current market value
Get-GDAXProductTicker -ProductID 'BTC-EUR' |Format-Table -AutoSize

# sell all your BTC with a Market order
$btcAccount = $accounts |Where-Object { $_.currency -eq 'BTC' } |Select-Object -First 1
New-GDAXOrder -Side sell -ProductID 'BTC-EUR' -Type market -Size $btcAccount.available -Place
```
GDAX-API is the shared dependency for the other modules, and GDAX-AUTH is required when invoking Private endpoints.
The others work independently from eachother.

# POSH-MOD-CBPRO
PowerShell Module collection for Coinbase Pro interaction

## Why
Simplify the interaction with the Coinbase Pro API. Making connecting to it and using it effortless and painless.

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
Use the CBPRO prefix when importing the modules, modules with dependencies on eachother rely on this prefix.

- ``cbpro-api`` handles the API request
- ``cbpro-auth`` provides Credential and authentication methods when nesseccary
- ``cbpro-accounts`` for your Accounts, History and Holds data
- ``cbpro-fills`` works with your recent Fills
- ``cbpro-marketdata`` gets public information like Products Currencies and Time
- ``cbpro-orders`` handles all your Order mutating, creating, listing and cancelling

```
Import-Module cbpro-api.psm1 -Prefix CBPRO -Force
Import-Module cbpro-auth.psm1 -Prefix CBPRO -Force
Import-Module cbpro-accounts.psm1 -Prefix CBPRO -Force
Import-Module cbpro-fills.psm1 -Prefix CBPRO -Force
Import-Module cbpro-marketdata.psm1 -Prefix CBPRO -Force
Import-Module cbpro-orders.psm1 -Prefix CBPRO -Force

# set the environment to use
Set-CBPROEnvironment "sandbox"
# supply credentials
Set-CBPROCredentials -Key 'thekeystring' -Passphrase 'thepassphrasestring' -Secret 'thebase64encodedsecret'

# list your accounts
Get-CBPROAccounts |Format-Table -AutoSize

# get the latest trade to see the current market value
Get-CBPROProductTicker -ProductID 'BTC-EUR' |Format-Table -AutoSize

# sell all your BTC with a Market orders
$btcAccount = $accounts |Where-Object { $_.currency -eq 'BTC' } |Select-Object -First 1
New-CBPROOrder -Side sell -ProductID 'BTC-EUR' -Type market -Size $btcAccount.available -Place
```
CBPRO-API is the shared dependency for the other modules, and CBPRO-AUTH is required when invoking Private endpoints.
The others work independently from eachother.
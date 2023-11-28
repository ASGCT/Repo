# Execute-RepoScript

Installs an N-able agent using a Server, Customer ID, and Token

## Syntax
```PowerShell
Install-NableAgent.ps1 [-Server] <ValidatePattern> [-CustomerID] <Int> [-Token] <ValidatePattern> [<CommonParameters>]
```
## Description

Installs the N-Able agent using server, token, and clientID

## Examples


###  Example 1 
```PowerShell
Install-NableAgent.ps1 n-able.Mycompany.com 123 12345678-hgjf-uetc-tyis-viu8osn7sioe
```

Installs the N-able agent for a N-able company named mycompany, with the customer id of 123 and using the token 12345678-hgjf-uetc-tyis-viu8osn7sioe

###  Example 2 
```PowerShell
Install-NableAgent.ps1 -Server n-able.Mycompany.com -CustomerID 123 -Token 12345678-hgjf-uetc-tyis-viu8osn7sioe
```

Installs the N-able agent for a N-able company named mycompany, with the customer id of 123 and using the token 12345678-hgjf-uetc-tyis-viu8osn7sioe.
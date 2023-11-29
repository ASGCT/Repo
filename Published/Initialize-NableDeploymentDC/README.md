# Initialize-NableDeployment

  Sets up a domain controller to push out the n-able agent for this client.
  ** Does not apply the group policy to any OU **

## Syntax
```PowerShell
Initialize-NableDeploymentDC.ps1 [-CustomerID] <Int> [-Token] <ValidatePattern> [<CommonParameters>]
```
## Description

Set up a group policy that will install the N-able agent on any new computer or any computer that is missing the n-able agent

## Examples


###  Example 1 
```PowerShell
Initialize-NableDeploymentDC.ps1 -CustomerID 261 -Token j43863j3-jfy9-jfu0-ls07-jdi8nch6yfdjo
```

Sets up the Domain controller with a group policy named NableAgentDeployment that can be assigned to any ou.

###  Example 2 
```PowerShell
Initialize-NableDeploymentDC.ps1 261 j43863j3-jfy9-jfu0-ls07-jdi8nch6yfdjo
```

Same as above
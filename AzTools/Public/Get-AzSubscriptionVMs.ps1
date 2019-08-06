function Get-AzSubscriptionVMs
{
    [CmdletBinding()]
    Param ()
    
    $SubscriptionVMs = [System.Collections.ArrayList]::new()

    $VMsRm = get-azresource -ODataQuery "`$filter=ResourceType eq 'Microsoft.compute/VirtualMachines'" 
    $VMsClassic = get-azresource -ODataQuery "`$filter=ResourceType eq 'Microsoft.ClassicCompute/virtualMachines'" 
    $null = $SubscriptionVMs.AddRange(@($VMsRm))
    $null = $SubscriptionVMs.AddRange(@($VMsClassic))    

    $SubscriptionVMs
}

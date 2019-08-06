function Get-AzVMIPAddresses
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([PSCustomObject])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]
        $AzureVM,

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            ParameterSetName = "Classic")]
        [Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResource]
        $ClassicVM
    )

    Begin
    {
    }
    Process
    {

        if ($PSBoundParameters.ContainsKey('AzureVM'))
        {
            $IPInfo = [pscustomobject][ordered] @{
                VMName     = $AzureVM.Name
                VMId       = $AzureVM.Id
                PrivateIPs = [System.Collections.ArrayList]::new()
                PublicIps  = [System.Collections.ArrayList]::new()
            }

            Get-azNetworkInterface -ResourceGroupName Rmilne-Tailspintoys-Canada | ForEach { $Interface = $_.Name; $IPs = $_ | Get-azNetworkInterfaceIpConfig | Select PrivateIPAddress; Write-Host $Interface $IPs.PrivateIPAddress }
            
    
            # Get all the network interfaces attached to this VM
            foreach ($NicInterface in $AzureVM.networkprofile.networkinterfaces)
            {
                # Get the network interface
                $nic = Get-azResource -ResourceId $nicInterface.id | Get-azNetworkInterface

                foreach ($IPConfiguration in $nic.ipconfigurationstext | convertfrom-json)
                {
                    $null = $IPInfo.PrivateIPs.Add($IPConfiguration.PrivateIpAddress)

                    if ($IPConfiguration.PublicIpAddress -and -not [string]::IsNullOrEmpty($IPConfiguration.PublicIpAddress.id))
                    {
                        $publicIPAddress = Get-azResource -ResourceId $IPConfiguration.PublicIpAddress.id | Get-azPublicIpAddress

                        if ($publicIPAddress.IpAddress -ne 'Not Assigned')
                        {
                            $null = $IPInfo.PublicIps.Add($publicIPAddress.IpAddress)
                        }
                    }
                }
            }
        }

        if ($PSBoundParameters.ContainsKey('ClassicVM'))
        {
            $IPInfo = [pscustomobject][ordered] @{
                VMName     = $ClassicVM.Name
                VMId       = $ClassicVM.Id
                PrivateIPs = 'UnableToAccessClassicVMIPAddress'
                PublicIps  = 'UnableToAccessClassicVMIPAddress'
            }
        }

        $IPInfo
    }
    End
    {
    }
}

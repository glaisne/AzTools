<#
.Synopsis
Gets public IP information for a collection of various resourse types.
.DESCRIPTION
Get-AzResourceIPAddress works on the following Azure resource types:
        Microsoft.Network/networkInterfaces
        Microsoft.Network/publicIPAddresses
        Microsoft.Web/sites
        Microsoft.Network/localNetworkGateways
        Microsoft.Storage/storageAccounts
        Microsoft.Sql/servers
        Microsoft.KeyVault/vaults
.EXAMPLE
Example of how to use this cmdlet
.EXAMPLE
Another example of how to use this cmdlet

.NOTES

Some code taken from https://blogs.msdn.microsoft.com/jrt/2017/07/03/get-azure-paas-endpoint-ips/
#>
function Get-AzResourceIPAddress
{
    [CmdletBinding()]
    [Alias()]
    Param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string]
        $ResourceGroupName,

        
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 1)]
        [string]
        $Name,

        
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 2)]
        [string]
        $ResourceType
    )

    Begin
    {
        function URLToIP
        {
            Param
            (
                # Param1 help description
                [Parameter(Mandatory = $true,
                    ValueFromPipeline = $true,
                    Position = 0)]
                [string] $URL
            )

            $URL = $URL.TrimStart("http://").TrimStart("https://")
            $URL = $URL.Split('/')[0]

            Resolve-DnsName $URL | ? { $_.gettype().fullname -eq 'Microsoft.DnsClient.Commands.DnsRecord_A' } | % ipaddress
        }
    }
    Process
    {

        switch ($ResourceType) 
        {
            'Microsoft.Network/networkInterfaces'
            {
                $Object = Get-azNetworkInterface -Name $Name -ResourceGroupName $ResourceGroupName
                Get-NetworkInterfacePrivateIp -NetworkInterface $Object
                break
            }
            'Microsoft.Network/publicIPAddresses'
            {
                $Object = Get-azPublicIpAddress -Name $Name -ResourceGroupName $ResourceGroupName
                Get-PublicIPAddressPublicIP -PublicIPAddress $Object
                break
            }
            'Microsoft.Web/sites'
            {
                $Object = Get-AzWebApp -Name $Name -ResourceGroupName $ResourceGroupName
                $Object.OutboundIpAddresses -split ',' | select -first 1
                break
            }
            'Microsoft.Network/localNetworkGateways'
            {
                $Object = Get-AzLocalNetworkGateway -ResourceGroupName $ResourceGroupName -Name $Name
                $object.GatewayIpAddress
                break
            }
            'Microsoft.Storage/storageAccounts'
            {
                $Object = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $Name
                $Endpoints = $object.primaryendpoints

                foreach ($endpoint in $($endpoints | gm -MemberType property | % name))
                {
                    if ($endpoints.$endpoint)
                    {
                        URLToIP -url $endpoints.$endpoint
                    }
                }
            }
            'Microsoft.Sql/servers'
            {
                URLToIP -URL "$Name`.database.windows.net"
            }
            'Microsoft.KeyVault/vaults'
            {
                $Vault = Get-AzKeyVault -VaultName $Name -ResourceGroupName $ResourceGroupName
                $VaultFQDN = $Vault.VaultUri.Substring(8, $Vault.VaultUri.Length - 9)
                URLToIP -url $VaultFQDN
            }
            Default 
            {
                Write-Error "Currently unable to process resource types '$($ResourceType)'"
            }
        }
    }
    End
    {
    }
}
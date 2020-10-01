<#
.SYNOPSIS
    Finds azure RM resources among all available subscriptions and Resource Groups
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES

    ToDo: 
     - Possibly remove the sub-search by resoruce group. What is the value/requirement for this?


    History:
    Version     Who             When            What
    1.0.0       Gene Laisne     ???             - Initial version made
    1.0.1       Gene Laisne     07/05/2018      - Added better looping through Subscriptions
                                                  Added progress bars for subscriptions and Resource Groups
    1.1.0       Gene Laisne     03212019        - Added finding resources by IPAddress
                                                - Added searching IPAddress on Network Interfaces by Private IP
#>

function Find-AzResource
{
    [CmdletBinding(DefaultParameterSetName = 'AllSubscriptionsResourceName')]
    [Alias()]
    [OutputType([OutputType])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory = $true, 
            ParameterSetName = 'AllSubscriptionsResourceName',
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [Parameter(Mandatory = $true, 
            ParameterSetName = 'SubscriptionNameResourceName',
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [Parameter(Mandatory = $true, 
            ParameterSetName = 'SubscriptionIdResourceName',
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string[]]
        $ResourceName,

        [Parameter(Mandatory = $true, 
            ParameterSetName = 'AllSubscriptionsResourceIPAddress',
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [Parameter(Mandatory = $true, 
            ParameterSetName = 'SubscriptionNameResourceIPAddress',
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [Parameter(Mandatory = $true, 
            ParameterSetName = 'SubscriptionIdResourceIPAddress',
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string[]]
        $IPAddress,

        [Parameter(Mandatory = $true, 
            ParameterSetName = 'AllSubscriptionsResourceDNSName',
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [Parameter(Mandatory = $true, 
            ParameterSetName = 'SubscriptionNameResourceDNSName',
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [Parameter(Mandatory = $true, 
            ParameterSetName = 'SubscriptionIdResourceDNSName',
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string[]]
        $DNSName,

        [Parameter(Position = 0,
            ParameterSetName = 'AllSubscriptionsResourceName')]
        [Parameter(Position = 0,
            ParameterSetName = 'AllSubscriptionsResourceIPAddress')]
        [Parameter(Position = 0,
            ParameterSetName = 'AllSubscriptionsResourceDNSName')]
        [Alias("All")]
        [switch]
        $AllSubscriptions,

        [Parameter(Position = 0,
            ParameterSetName = 'SubscriptionNameResourceName')]
        [Parameter(Position = 0,
            ParameterSetName = 'SubscriptionNameResourceIPAddress')]
        [Parameter(Position = 0,
            ParameterSetName = 'SubscriptionNameResourceDNSName')]
        [String[]]
        $SubscriptionName,

        [Parameter(Position = 0,
            ParameterSetName = 'SubscriptionIdResourceName')]
        [Parameter(Position = 0,
            ParameterSetName = 'SubscriptionIdResourceIPAddress')]
        [Parameter(Position = 0,
            ParameterSetName = 'SubscriptionIdResourceDNSName')]
        [String[]]
        $SubscriptionId
    )

    Begin
    {
        $ResourceTypes = [System.Collections.ArrayList]::new()
        $null = $ResourceTypes.Add('Microsoft.Network/networkInterfaces')
        $null = $ResourceTypes.Add('Microsoft.Network/publicIPAddresses')
        $null = $ResourceTypes.Add('Microsoft.Web/sites')
        $null = $ResourceTypes.Add('Microsoft.Network/localNetworkGateways')
        $null = $ResourceTypes.Add('Microsoft.Storage/storageAccounts')
        $null = $ResourceTypes.Add('Microsoft.Sql/servers')
        $null = $ResourceTypes.Add('Microsoft.KeyVault/vaults')

        $PubicIPUsableResources = [System.Collections.ArrayList]::new()
        $null = $PubicIPUsableResources.Add('Microsoft.Network/virtualNetworkGateways')  #
        $null = $PubicIPUsableResources.Add('Microsoft.Network/loadBalancers')
        $null = $PubicIPUsableResources.Add('Microsoft.Network/networkInterfaces')   # 
        $null = $PubicIPUsableResources.Add('Microsoft.Network/applicationGateways')
        $null = $PubicIPUsableResources.Add('Microsoft.Network/azureFirewalls')

        Write-Warning "Find-azResource will only find resources of these types:"
        $ResourceTypes | ft -AutoSize | out-string -stream | ? { -not [string]::IsnullOrEmpty($_) } | % { Write-Warning $_ }
        Write-Warning "Finding resources by DNSName is unproven at this point."

        Write-verbose "Note: Public IP Addresses will be used with the following resoruce types:"
        foreach ($entry in $PubicIPUsableResources)
        {

        }
    }
    Process
    {
        #
        #    Get Subscriptions
        #


        Write-Verbose "[$(Get-Date -format G)] Getting Subscriptions"
        $SubscriptionPool = [System.Collections.ArrayList]::new()
        switch -Regex ($PSCmdlet.ParameterSetName)
        {
            'AllSubscriptions.*'
            {
                try
                {
                    $SubscriptionPool.AddRange(@($(Get-azSubscription -ErrorAction 'Stop' | ? {$_.State -ne 'disabled'})))
                }
                catch
                {
                    $err = $_
                    Write-Warning "Failed to access any Subscriptions : $($err.exception.Message)"
                }
                break
            }
            'SubscriptionName.*'
            {

                foreach ($SubName in $SubscriptionName)
                {
                    try
                    {
                        $Sub = Get-azSubscription -SubscriptionName $SubName -ErrorAction Stop
                        $null = $SubscriptionPool.Add($Sub)
                    }
                    catch
                    {
                        $err = $_
                        Write-Warning "Failed to access Subscription ($SubName) : $($err.exception.Message)"
                    }
                }
                $SubscriptionPool = $SubscriptionPool.ToArray()
                break
            }
            'SubscriptionId.*'
            {
                foreach ($SubId in $SubscriptionId)
                {
                    try
                    {
                        $Sub = Get-azSubscription -SubscriptionId $SubId -ErrorAction Stop
                        $null = $SubscriptionPool.Add($Sub)
                    }
                    catch
                    {
                        $err = $_
                        Write-Warning "Failed to access Subscription ($SubId) : $($err.exception.Message)"
                    }
                }
                $SubscriptionPool = $SubscriptionPool.ToArray()
                break
            }
            Default { Throw 'could not find parameter name set.' }
        }


        #
        #    Search
        #


        $i = 0
        :subloop foreach ($Sub in $SubscriptionPool)
        {
            Write-Verbose "Searching Subscription $($Sub.Name) : $($Sub.Id)"

            $PrecentComplete = $([math]::round($($i / $SubscriptionPool.count * 100), 2))
            Write-Progress -Id 0 -Activity "Processing Subscription $($Sub.Name)`..." -Status "$PrecentComplete %" -PercentComplete $PrecentComplete
        
        
            #
            #    select the subscription
            #
        
        
            # Get Subscription information
            $SubscriptionName = $Sub.Name
            $SubscriptionId = $Sub.Id

            if ($SubscriptionId.gettype().fullname -eq 'System.String[]')
            {
                $SubscriptionId = $SubscriptionId[0]
            }
        
            if ($SubscriptionName -in $SubscriptionExclusionList)
            {
                Continue
            }
        
            # Try up to 10 times to swich to the specific subscription
            $TryCount = 0
            while (-Not $(Test-azCurrentSubscription -Id ([string] $SubscriptionId)) -or $TryCount -gt 10)
            {
                try
                {
                    $null = Select-azSubscription -SubscriptionId ([string] $SubscriptionId) -erroraction Stop
                }
                catch
                {
                    $err = $_
                    Write-Warning "Failed to select Azure RM Subscription by SubscriptionId $SubscriptionId : $($err.exception.message)"
                }
                $TryCount++
            }
        
            # Test if we are in the proper subscription context
            if ($(get-azcontext).subscription.id -ne $SubscriptionId)
            {
                Write-warning "Failed to set the proper context : ($($(get-azcontext).subscription.name))"
                continue
            }

            Write-Verbose "[$(Get-Date -format G)] Looping through each Resource Group in subscriptoin $SubscriptionName"
            $ResoruceGroups = Get-azResourceGroup
            $j = 0
            foreach ($ResourceGroup in $ResoruceGroups)
            {
                $PrecentComplete = $([math]::round($($j / ($ResoruceGroups | measure).count * 100), 2))
                Write-Progress -Id 1 -Activity "Processing Resoruce Groups $($ResourceGroup.ResourceGroupName)`..." -Status "$PrecentComplete %" -PercentComplete $PrecentComplete

                Write-Verbose "Searching within Resource Group $($resourceGroup.ResourceId)"


                #
                #    Find by Resource Name
                #


                if ($psBoundParameters.ContainsKey('ResourceName'))
                {
                    foreach ($Resource in $ResourceName)
                    {
                        get-azResource -ResourceGroupName $ResourceGroup.ResourceGroupName | ? { $_.Name -like $Resource }
                    }
                }


                #
                #    Find by IP Address or DNS Name
                #


                if ($PSCmdlet.ParameterSetName -like "*IPAddress" -or $PSCmdlet.ParameterSetName -like "*DNSName")
                {
                    $Resources = get-azResource -ResourceGroupName $ResourceGroup.ResourceGroupName | ? { $_.ResourceType -in $ResourceTypes }

                    foreach ($Resource in $Resources)
                    {
                        $FoundIP = Get-AzResourceIPAddress -ResourceGroupName $ResourceGroup.ResourceGroupName -Name $Resource.Name -ResourceType $Resource.ResourceType

                        if ($PSCmdlet.ParameterSetName -like "*IPAddress")
                        {
                            foreach ($ip in @($FoundIP))
                            {
                                if ($IP -eq $IPAddress)
                                {
                                    $Resource
                                    break subloop
                                }
                            }
                        }

                        if ($PSCmdlet.ParameterSetName -like "*DNSName")
                        {
                            $HostName = [System.Net.Dns]::GetHostEntry($IP).hostname
                            if ($HostName -eq $DNSName)
                            {
                                $Resource
                            }
                        }


                        # switch ($Resource.ResourceType) 
                        # {
                        #     'Microsoft.Network/networkInterfaces'
                        #     {
                        #         $FoundIP = Get-AzResourceIPAddress -ResourceGroupName $ResourceGroup.ResourceGroupName -Name $Resource.Name -ResourceType $Resource.ResourceType
                        #         # $Object = Get-azNetworkInterface -Name $Resource.Name -ResourceGroupName $ResourceGroup.ResourceGroupName
                        #         # $IP = Get-NetworkInterfacePrivateIp -NetworkInterface $Object
                        #         break
                        #     }
                        #     'Microsoft.Network/publicIPAddresses'
                        #     {
                        #         $FoundIP = Get-AzResourceIPAddress -ResourceGroupName $ResourceGroup.ResourceGroupName -Name $Resource.Name -ResourceType $Resource.ResourceType
                        #         # $Object = Get-azPublicIpAddress -Name $Resource.Name -ResourceGroupName $ResourceGroup.ResourceGroupName
                        #         # $IP = Get-PublicIPAddressPublicIP -PublicIPAddress $Object
                        #         break
                        #     }
                        #     'Microsoft.Web/sites'
                        #     {
                        #         $FoundIP = Get-AzResourceIPAddress -ResourceGroupName $ResourceGroup.ResourceGroupName -Name $Resource.Name -ResourceType $Resource.ResourceType
                        #         # $Object = Get-AzWebApp -Name $Resource.Name -ResourceGroupName $ResourceGroup.ResourceGroupName
                        #         # $IP = $Object.OutboundIpAddresses -split ',' | select -first 1
                        #         break
                        #     }
                        #     'Microsoft.Network/localNetworkGateways'
                        #     {
                        #         $FoundIP = Get-AzResourceIPAddress -ResourceGroupName $ResourceGroup.ResourceGroupName -Name $Resource.Name -ResourceType $Resource.ResourceType
                        #         # $Object = Get-AzLocalNetworkGateway -ResourceGroupName $ResourceGroup.ResourceGroupName -Name $Resource.Name
                        #         # $ip = $object.GatewayIpAddress
                        #         break
                        #     }
                        #     'Microsoft.Storage/storageAccounts'
                        #     {
                        #         $FoundIP = Get-AzResourceIPAddress -ResourceGroupName $ResourceGroup.ResourceGroupName -Name $Resource.Name -ResourceType $Resource.ResourceType
                        #         # $Object = Get-AzLocalNetworkGateway -ResourceGroupName $ResourceGroup.ResourceGroupName -Name $Resource.Name
                        #         # $ip = $object.GatewayIpAddress
                        #         break
                        #     }
                        #     Default 
                        #     {
                        #         Write-verbose "Currently unable to process resource types '$($Resource.ResourceType)'"
                        #     }
                        # }
                    }
                }


                $j++
            }
            Write-Progress -Id 1 -Completed -Activity 'Processing Resoruce Groups $($ResoruceGroups.ResourceGroupName)`...'
            $i++
        }
        Write-Progress -Id 0 -Completed -Activity 'Processing Subscription $($Sub.Name)`...'
    }
    End
    {
    }
}





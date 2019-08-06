<#
.Synopsis
Short description
.DESCRIPTION
Long description
.EXAMPLE
Example of how to use this cmdlet
.EXAMPLE
Another example of how to use this cmdlet
#>
function Get-AzSubscriptionBillingInfo
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([OutputType])]
    Param
    (
    )

    Begin
    {
        $Context = get-azcontext
        $SubscriptionName = $context.name.split(" (")[0]
    }
    Process
    {
        $BillingPeriodName = get-date ([datetime]::now.AddMonths(-1)) -f 'yyyyMM'

        try
        {
            $UsageInfo = Get-AzConsumptionUsageDetail -BillingPeriodName $BillingPeriodName -IncludeMeterDetails -ErrorAction Stop
        }
        catch [Microsoft.Azure.Management.Consumption.Models.ErrorResponseException]
        {
            if ($($err.exception.response.statuscode) -eq 'NoContent')
            {
                Write-Error "Usage information returned '$($err.exception.response.statuscode)' for BillingPeriodName $BillingPeriodName in subscription $SubscriptionName"
            }
        }
        catch
        {
            Write-Error -Message $err.exception.message
        }

        $InstanceInfoGroup = $UsageInfo | group InstanceId

        $DateStamp = $BillingPeriodName.Insert(4, '-')
        foreach ($InstanceInfo in $InstanceInfoGroup)
        {
            [PSCustomObject][Ordered] @{
                Date              = $DateStamp
                Subscription      = $SubscriptionName
                ResourceGroupName = (Get-ResourcegroupNameFromId -idString $InstanceInfo.group[0].InstanceId)
                Resource          = $InstanceInfo.group.InstanceName | select -Unique
                ResourceType      = $InstanceInfo.group.ConsumedService | select -Unique
                ResourceLocation  = $InstanceInfo.group.InstanceLocation | select -Unique
                Cost              = [math]::Round(($InstanceInfo.Group.PretaxCost | measure -sum | % sum), 2)
            }
        }

        # $UsageInfo | Select AccountName, UsageStart, UsageEnd, BillingPreiodName, SubscriptionName, ConsumedService, InstanceName, InstanceLocation,
        # CostCenter, DepartmentName,
        # @{l = 'MeterName'; e = {$_.Meterdetails.MeterName}},
        # @{l = 'MeterCategory'; e = {$_.Meterdetails.MeterCategory}},
        # @{l = 'MeterSubCategory'; e = {$_.Meterdetails.MeterSubCategory}},
        # @{l = 'MeterUnit'; e = {$_.Meterdetails.Unit}},
        # PretaxCost,
        # Product,
        # UsageQuantity,
        # @{l = 'PretaxCost x UsageQuantity'; e = {$_.PretaxCost * $_.UsageQuantity}},
        # InstanceId | sort InstanceName

    }
    End
    {
    }
}

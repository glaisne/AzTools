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
function Find-AzUnusedWebApp
{
    [CmdletBinding()]
    Param
    (
    )

    $webApps = Get-AzWebApp

    $StartTime = [datetime]::now.AddDays(-30)

    Foreach ($webApp in $webApps)
    {
        # Get connection metrics
        $ConnectionMaximumMetrics = get-azMetric -ResourceId $webApp.Id -StartTime $StartTime -TimeGrain (New-TimeSpan -Hours 1) -metricName 'AppConnections' -AggregationType Maximum
        $ConnectionAverageMetrics = get-azMetric -ResourceId $webApp.Id -StartTime $StartTime -TimeGrain (New-TimeSpan -Hours 1) -metricName 'AppConnections' -AggregationType Average

        #$DTUConsumptionPercentage30DayAverage = [math]::round($($dtu_consumptionMetrics.Data.average | measure -Average | % Average), 2)
        $Connection30DayMaximum = [math]::round($($ConnectionMaximumMetrics.Data.Maximum | measure -Maximum | % Maximum), 2)
        $Connection30DayMinimum = [math]::round($($ConnectionAverageMetrics.Data.Minimum | measure -Minimum | % Minimum), 2)

        $Unused = $Connection30DayMaximum -le 0

        if ($Unused)
        {

            [pscustomobject] [ordered] @{
                ResourceGroupName      = $webApp.ResourceGroup
                ServerFarmName         = $webApp.ServerFarmId.split('/')[-1]
                Name                   = $webApp.name
                Connection30DayMaximum = $Connection30DayMaximum
                Connection30DayMinimum = $Connection30DayMinimum
                Unused                 = $Unused
            }
        }
    }
}




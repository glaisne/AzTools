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
function Find-AzOverProvisionedSQLDatabase
{
    [CmdletBinding()]
    [Alias()]
    Param
    (
    )

    Begin
    {
    }
    Process
    {
        $StartTime = [datetime]::now.AddDays(-30)

        foreach ($db in get-azsqlserver | get-azsqldatabase)
        {
            # $dtu_consumptionMetrics = get-azMetric -ResourceId $Db.ResourceId -StartTime $StartTime -TimeGrain (New-TimeSpan -Hours 1) -metricName 'dtu_consumption_percent'
            # $dtu_usedMaximumMetrics = get-azMetric -ResourceId $Db.ResourceId -StartTime $StartTime -TimeGrain (New-TimeSpan -Hours 1) -metricName 'dtu_used' -AggregationType Maximum
            # $dtu_usedMinimumMetrics = get-azMetric -ResourceId $Db.ResourceId -StartTime $StartTime -TimeGrain (New-TimeSpan -Hours 1) -metricName 'dtu_used' -AggregationType Minimum
            # # $ConnectionsMetrics = get-azMetric -ResourceId $Db.ResourceId -StartTime $StartTime -TimeGrain (New-TimeSpan -Hours 1)  -metricName 'connection_successful' 
            # # $dtu_usedMetrics    = get-azMetric -ResourceId $Db.ResourceId -StartTime $StartTime -TimeGrain (New-TimeSpan -minutes 15)  -metricName 'dtu_used' 
            # # $storageMetrics    = get-azMetric -ResourceId $Db.ResourceId -StartTime $StartTime -TimeGrain (New-TimeSpan -Days 1)  -metricName 'storage' 
    
            # $DTUConsumptionPercentage30DayAverage = [math]::round($($dtu_consumptionMetrics.Data.average | measure -Average | % Average),2)
            # $DTUConsumption30DayMaximum = [math]::round($($dtu_usedMaximumMetrics.Data.Maximum | measure -Maximum | % Maximum),2)
            # $DTUConsumption30DayMinimum = [math]::round($($dtu_usedMinimumMetrics.Data.Minimum | measure -Minimum | % Minimum), 2)
            
            #------------------
            $dtu_consumptionMetrics = get-azMetric -ResourceId $Db.ResourceId -StartTime $StartTime -TimeGrain (New-TimeSpan -Hours 1) -metricName 'dtu_consumption_percent'
            $dtu_usedMaximumMetrics = get-azMetric -ResourceId $Db.ResourceId -StartTime $StartTime -TimeGrain (New-TimeSpan -Hours 1) -metricName 'dtu_used' -AggregationType Maximum
            $dtu_usedMinimumMetrics = get-azMetric -ResourceId $Db.ResourceId -StartTime $StartTime -TimeGrain (New-TimeSpan -Hours 1) -metricName 'dtu_used' -AggregationType Minimum

            $DTUConsumptionPercentage30DayAverage = [math]::round($($dtu_consumptionMetrics.Data.average | measure -Average | % Average), 2)
            $DTUConsumption30DayMaximum = [math]::round($($dtu_usedMaximumMetrics.Data.Maximum | measure -Maximum | % Maximum), 2)
            $DTUConsumption30DayMinimum = [math]::round($($dtu_usedMinimumMetrics.Data.Minimum | measure -Minimum | % Minimum), 2)

            $overprovisioned = Test-AzSqlDbOverprovisioned -ResourceGroupName $db.ResourceGroupName  -DatabaseName $db.DatabaseName  -ServerName $db.ServerName

            [pscustomobject] [ordered] @{
                ResourceGroupName                    = $db.ResourceGroupName
                ServerName                           = $db.ServerName
                DatabaseName                         = $db.DatabaseName
                DTUConsumptionPercentage30DayAverage = $DTUConsumptionPercentage30DayAverage
                DTUConsumption30DayMaximum           = $DTUConsumption30DayMaximum
                DTUConsumption30DayMinimum           = $DTUConsumption30DayMinimum
                DTULimit                             = $Db.Capacity
                OverProvisioned                      = $overprovisioned
            }
        }
    }
    End
    {
    }
}
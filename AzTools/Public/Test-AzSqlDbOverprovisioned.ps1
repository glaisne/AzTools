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
function Test-AzSqlDbOverprovisioned
{
    [CmdletBinding()]
    [Alias()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string]
        $ResourceGroupName,

        # Param2 help description
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 1)]
        [string]
        $DatabaseName,

        # Param2 help description
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 2)]
        [string]
        $ServerName
    )

    Begin
    {
    }
    Process
    {
        try
        {
            $Db = get-azsqldatabase -ResourceGroupName $ResourceGroupName  -DatabaseName $DatabaseName  -ServerName $ServerName # |? {$_.DatabaseName -eq $DatabaseName -and $_.ResourceGroupName -eq $ResourceGroupName}
        }
        catch
        {
            throw $_
        }

        $StartTime = [datetime]::now.AddDays(-30)

        # Percentage of DTU capacity being used.
        $dtu_consumptionMetrics = get-azMetric -ResourceId $Db.ResourceId -StartTime $StartTime -TimeGrain (New-TimeSpan -Hours 1) -metricName 'dtu_consumption_percent'

        # Maximum DTU values
        $dtu_usedMaximumMetrics = get-azMetric -ResourceId $Db.ResourceId -StartTime $StartTime -TimeGrain (New-TimeSpan -Hours 1) -metricName 'dtu_used' -AggregationType Maximum

        # Minimum DTU values
        $dtu_usedMinimumMetrics = get-azMetric -ResourceId $Db.ResourceId -StartTime $StartTime -TimeGrain (New-TimeSpan -Hours 1) -metricName 'dtu_used' -AggregationType Minimum

        $DTUConsumptionPercentage30DayAverage = [math]::round($($dtu_consumptionMetrics.Data.average | measure -Average | % Average),2)
        $DTUConsumption30DayMaximum = [math]::round($($dtu_usedMaximumMetrics.Data.Maximum | measure -Maximum | % Maximum),2)
        $DTUConsumption30DayMinimum = [math]::round($($dtu_usedMinimumMetrics.Data.Minimum | measure -Minimum | % Minimum), 2)

        if ($DTUConsumptionPercentage30DayAverage -lt 50 -and $DTUConsumption30DayMaximum -lt ($Db.Capacity * .8))
        {
            $true
        }
        else
        {
            $false
        }
    }
    End
    {
    }
}
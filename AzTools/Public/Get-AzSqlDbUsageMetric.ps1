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
function Get-AzSqlDbUsageMetric
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

        $StartTime = [datetime]::now.AddDays(-1)

        $dtu_limitMetrics   = get-azMetric -ResourceId $Db.ResourceId -StartTime $StartTime -TimeGrain (New-TimeSpan -Hours 1) -metricName 'dtu_limit'
        $ConnectionsMetrics = get-azMetric -ResourceId $Db.ResourceId -StartTime $StartTime -TimeGrain (New-TimeSpan -Hours 1)  -metricName 'connection_successful' 
        $dtu_usedMetrics    = get-azMetric -ResourceId $Db.ResourceId -StartTime $StartTime -TimeGrain (New-TimeSpan -minutes 15)  -metricName 'dtu_used' 
        $storageMetrics    = get-azMetric -ResourceId $Db.ResourceId -StartTime $StartTime -TimeGrain (New-TimeSpan -Days 1)  -metricName 'storage' 

        #Write-host "Status:  $($vmStatus.statuses |? {$_.code -like "PowerState*"} | % displayStatus)"
        Write-host "Datapoints: $($CPUMetrics.Data.count)"
        Write-host "Succesful connections: $($ConnectionsMetrics.Data.Total | measure -sum | % sum)"
        Write-host "DTU Limit: $($dtu_limitMetrics.Data.Average | measure -average | % Average)"
        Write-host "Storage: $([math]::round($(($storageMetrics.Data.Maximum | measure -Maximum).Maximum /1024/1024),1)) MB"
        Write-host "Minimum: $([math]::round($($dtu_usedMetrics.Data.Average | Measure-Object -Minimum | % Minimum),2))"
        Write-host "Maximum: $([math]::round($($dtu_usedMetrics.Data.Average | Measure-Object -Maximum | % Maximum),2))"
        Write-host "Average: $([math]::round($($dtu_usedMetrics.Data.Average | Measure-Object -Average | % Average),2))"

        show-graph -datapoints ($dtu_usedMetrics.data | % average) -XAxisTitle "$DatabaseName - 24 hours" -YAxisTitle "DTU Used"
    }
    End
    {
    }
}
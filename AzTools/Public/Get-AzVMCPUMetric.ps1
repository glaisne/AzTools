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
function get-AzVmCpuMetric
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
        $Name
    )

    Begin
    {
    }
    Process
    {
        try
        {
            $vm = get-azvm -ResourceGroupName $ResourceGroupName -Name $Name -ErrorAction 'Stop'
        }
        catch
        {
            throw $_
        }
        
        try
        {
            $vmStatus = get-azvm -ResourceGroupName $ResourceGroupName -Name $Name -status -ErrorAction 'Stop'
        }
        catch
        {
            throw $_
        }

        $CPUAveMetrics = get-azMetric -ResourceId $vm.Id -StartTime ([datetime]::now.AddDays(-1)) -TimeGrain (New-TimeSpan -minutes 15 ) -metricName 'Percentage CPU' 
        $CPUMaxMetrics = get-azMetric -ResourceId $vm.Id -StartTime ([datetime]::now.AddDays(-1)) -TimeGrain (New-TimeSpan -minutes 15 ) -metricName 'Percentage CPU' -AggregationType Maximum
        $CPUMinMetrics = get-azMetric -ResourceId $vm.Id -StartTime ([datetime]::now.AddDays(-1)) -TimeGrain (New-TimeSpan -minutes 15 ) -metricName 'Percentage CPU' -AggregationType Minimum

        Write-host "Status:  $($vmStatus.statuses |? {$_.code -like "PowerState*"} | % displayStatus)"
        Write-host "Minimum: $([math]::round($($CPUMinMetrics.Data.Minimum | Measure-Object -Minimum | % Minimum),2))"
        Write-host "Maximum: $([math]::round($($CPUMaxMetrics.Data.Maximum | Measure-Object -Maximum | % Maximum),2))"
        Write-host "Average: $([math]::round($($CPUAveMetrics.Data.Average | Measure-Object -Average | % Average),2))"

        show-graph -datapoints ($CPUAveMetrics.data | % average) -XAxisTitle "$Name - 24 hours" -YAxisTitle "Percentage CPU"
    }
    End
    {
    }
}
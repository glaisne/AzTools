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
function Remove-AzSqlServerFirewallrule
{
    [CmdletBinding()]
    Param
    (
        [Parameter(ParameterSetName = 'SubscriptionName',
            Mandatory = $true)]
        [String[]]
        $SubscriptionName,
    
        [Parameter(ParameterSetName = 'SubscriptionId',
            Mandatory = $true)]
        [String[]]
        $SubscriptionId,
        
        [Parameter(Mandatory = $true)]
        [string[]]
        $SQLServer,
    
        [Parameter(Mandatory = $true)]
        [string]
        $firewallRuleName
    )
    
    #-----------------------------
    # Variables
    #-----------------------------
    $GuidRegex = "^[{(]?[0-9A-F]{8}[-]?([0-9A-F]{4}[-]?){3}[0-9A-F]{12}[)}]?$"
    $SubscriptionPool = [System.Collections.ArrayList]::new()
    
    
    #-----------------------------
    # Functions
    #-----------------------------
    
    function GetMyIp()
    {
        # Get local IP Address
        $url = "http://checkip.dyndns.com"
        $r = Invoke-WebRequest $url -verbose:$false
        $r.content.split(' ')[-1].split('<')[0]
        # $r.ParsedHtml.getElementsByTagName("body")[0].innertext.trim().split(' ')[-1]
    }
    
    
    #-----------------------------
    # Main
    #-----------------------------
    
    
    Write-Verbose "[$(Get-Date -format G)] Getting Subscriptions"
    switch ($PSCmdlet.ParameterSetName)
    {
        'SubscriptionName'
        {
            
            foreach ($SubName in $SubscriptionName)
            {
                try
                {
                    $Sub = Get-AzSubscription -SubscriptionName $SubName -ErrorAction Stop
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
        'SubscriptionId'
        {
            foreach ($SubId in $SubscriptionId)
            {
                try
                {
                    $Sub = Get-AzSubscription -SubscriptionId $SubId -ErrorAction Stop
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
    
    
    foreach ($subscription in $SubscriptionPool)
    {
        Foreach ($SqlSrv in $SQLServer)
        {
            # Get the SQL Server
            $Server = $null
            try
            {
                $Server = Get-AzSqlServer -name $sqlSrv -ErrorAction 'stop'
            }
            catch
            {
                $err = $_
                Write-Warning "[$(Get-Date -format G)] Failed to access SQL server $sqlServer in Subscription $($Subscription.Name)"
                Write-Warning "[$(Get-Date -format G)] Skipping SQL server"
                Continue
            }
    
            if (-not $Server)
            {
                Write-Warning "[$(Get-Date -format G)] Failed to get SQL Server $sqlServer"
                continue
            }
    
            $NewFirewallruleParams = @{
                FirewallRuleName = $firewallRuleName
            }
    
            try
            {
                $Server | Az.Sql\Remove-AzSqlServerFirewallRule @NewFirewallruleParams -ErrorAction 'Stop'
            }
            catch
            {
                $err = $_
                Write-Warning "[$(Get-Date -format G)] Failed to remove firewall rule ($firewallRuleName) on sql server $sqlServer"
                Write-Warning "[$(Get-Date -format G)] Error: $($err.exception.message)"
                Continue
            }
        }
    }
}
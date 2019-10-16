function Test-AzSQLServerHasDatabase
{
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string]
        $ResourceGroupName,
        
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 1)]
        [string]
        $SqlServerName
    )

    Begin
    {
    }
    Process
    {
        try
        {
            $sqlServer = Get-AzSqlServer -ResourceGroupName $ResourceGroupName -Name $SqlServerName
        }
        catch
        {
            throw $_
        }

        $sqlDatabases = $sqlServer | Get-AzSqlDatabase

        if (($sqlDatabases | measure).count -eq 1 -and ($sqlDatabases | select -first 1).DatabaseName -eq 'master')
        {
            return $false
        }
        else
        {
            return $true
        }
    }
    End
    {
    }
}

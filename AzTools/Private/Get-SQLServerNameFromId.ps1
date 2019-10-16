
function Get-SQLServerNameFromId
{
    param(
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [alias("StringId", "ResourceId")]
        [string]
        $id
    )
    
    process
    {

        $match = [regex]::Match($id, "Microsoft.Sql/servers/([A-Za-z0-9\-]+)/?")
        if ($match.Success)
        {
            $match.groups[1].value
        }
        else
        {
            $null
        }
        
    }
}

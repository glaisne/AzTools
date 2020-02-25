# mostly taken from https://github.com/Azure/azure-powershell/blob/master/src/Compute/Compute/VirtualMachine/VirtualMachineBaseCmdlet.cs
<#
        protected string GetResourceGroupNameFromId(string idString)
        {
            var match = Regex.Match(idString, @"resourceGroups/([A-Za-z0-9\-]+)/");
            return (match.Success)
                ? match.Groups[1].Value
                : null;
        }
#>
function Get-ResourcegroupNameFromId
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

        $match = [regex]::Match($id, "resourceGroups/([A-Za-z0-9\-]+)/?", [system.Text.RegularExpressions.RegexOptions]::IgnoreCase)
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
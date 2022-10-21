function Import-AdfsPowershellModule {
    $adfsModule = "ADFS"

    try {
        if ($null -eq (Get-Module $adfsModule -ErrorAction SilentlyContinue)) {
            Import-Module $adfsModule
        }
    }
    catch {
        return $Error[0]
    }
}

# Export functions
$exportMembers = @{
    Function = 'Import-AdfsPowershellModule'
}
Export-ModuleMember @exportMembers
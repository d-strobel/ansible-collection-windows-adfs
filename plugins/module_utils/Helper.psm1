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

function Get-AdfsTransformRules {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ $_.GetType().FullName -eq 'Ansible.Basic.AnsibleModule' })]
        $Module
    )

    begin {
        [string] $transformRule = ""
        [string] $ldapRuleTypes = ""
        [string] $ldapRuleQuery = ""
    }

    process {
        # Build transform rules for claims
        foreach ($claimAttribute in $Module.Params.claim_attributes) {

            switch ($claimAttribute.Type) {
                'group' {
                    # Get SID of group
                    try {
                        $groupObject = New-Object System.Security.Principal.NTAccount("$(($Module.Params.domain).ToUpper())", "$($claimAttribute.Condition)")
                        $groupSID = $groupObject.Translate([System.Security.Principal.SecurityIdentifier]) | Select-Object -ExpandProperty Value
                    }
                    Catch {
                        throw $Error[0]
                    }

                    # Build rule for group
                    $transformRule += "
                        @RuleTemplate = `"EmitGroupClaims`"
                        @RuleName = `"Group $($claimAttribute.Condition)`"
                        c:[Type == `"http://schemas.microsoft.com/ws/2008/06/identity/claims/groupsid`", Value == `"$groupSID`", Issuer == `"AD AUTHORITY`"]
                        => issue(Type = `"http://schemas.xmlsoap.org/claims/Group`", Value = `"$($claimAttribute.Issuance)`", Issuer = c.Issuer, OriginalIssuer = c.OriginalIssuer, ValueType = c.ValueType);
                    "
                }
                'ldap' {
                    # Query output for this claim
                    $ldapRuleQuery += "$($claimAttribute.Issuance),"

                    # Type for this claim
                    if ($claimAttribute.Condition -match "givenname|surname|emailaddress") {
                        $ldapRuleTypes += "`"http://schemas.xmlsoap.org/ws/2005/05/identity/claims/$($claimAttribute.Condition)`", "
                    }
                    elseif ($claimAttribute.Condition -eq "windowsaccountname") {
                        $ldapRuleTypes += "`"http://schemas.microsoft.com/ws/2008/06/identity/claims/$($claimAttribute.Condition)`", "
                    }
                    else {
                        $ldapRuleTypes += "`"$($claimAttribute.Condition)`","
                    }
                }
                Default {
                    throw "Claim type does not match 'group' OR 'ldap'."
                }
            }
        }

        if ($ldapRuleQuery) {
            # Trim strings for claim rules
            $ldapRuleQuery = $ldapRuleQuery.TrimEnd(' , ')
            $ldapRuleTypes = $ldapRuleTypes.TrimEnd(' , ')

            # Build transform rule for ldap claims
            $transformRule += "
            @RuleTemplate = `"LdapClaims`"
            @RuleName = `"LDAP Claims`"
            c:[Type == `"http://schemas.microsoft.com/ws/2008/06/identity/claims/windowsaccountname`", Issuer == `"AD AUTHORITY`"]
            => issue(store = `"Active Directory`", types = ($ldapRuleTypes), query = `";$ldapRuleQuery;{0}`", param = c.Value);
        "
        }
    }

    end {
        return $transformRule
    }
}

# Export functions
$exportMembers = @{
    Function = 'Import-AdfsPowershellModule', 'Get-AdfsTransformRules'
}
Export-ModuleMember @exportMembers
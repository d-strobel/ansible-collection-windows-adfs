#!powershell

# Copyright: (c) 2022, Dustin Strobel (@d-strobel), Yasmin Hinel (@seasxlticecream)
# GNU General Public License v3.0+ (see LICENSE or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell Ansible.ModuleUtils.AddType

$spec = @{
    options             = @{
        group_identifier = @{ type = "str"; required = $true }
        name             = @{ type = "str" }
        description      = @{ type = "str" }
        redirect_uri     = @{ type = "list" }
        logout_uri       = @{ type = "str" }
        state            = @{ type = "str"; choices = "absent", "present"; default = "present" }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

# ErrorAction
$ErrorActionPreference = 'Stop'

switch ($module.Params.state) {
    "absent" {
        $present = $false
    }
    "present" {
        $present = $true
    }
}

# Ensure powershell module is loaded
$adfs_module = "ADFS"

try {
    if ($null -eq (Get-Module $adfs_module -ErrorAction SilentlyContinue)) {
        Import-Module $adfs_module
    }
}
catch {
    $module.FailJson("Failed to load PowerShell module $adfs_module.", $_)
}


# Search for native application group
$adfsNativeClientApplication = Get-AdfsNativeClientApplication -ApplicationGroupIdentifier $module.Params.group_identifier -ErrorAction SilentlyContinue

# Create native client application if it not exists
if ($null -eq $adfsNativeClientApplication -and $present) {
    # Client-ID
    $nativeApplicationIdentifier = (New-Guid).Guid

    try {
        Add-AdfsNativeClientApplication `
            -ApplicationGroupIdentifier $module.Params.group_identifier `
            -Name $module.Params.name `
            -Identifier $nativeApplicationIdentifier `
            -RedirectUri $module.Params.redirect_uri `
            -Description $module.Params.description `
            -LogoutUri $module.Params.logout_uri `
            -WhatIf:$module.CheckMode
    }
    catch {
        $module.FailJson("Failed to add native client application.", $_)
    }
    $module.Result.changed = $true
    $module.ExitJson()
}
elseif ($null -eq $adfsNativeClientApplication -and -not $present) {
    $module.ExitJson()
}

# Set application_identifier
$module.Result.application_identifier = $adfsNativeClientApplication.Identifier

# Remove native client application if state == absent
if ($adfsNativeClientApplication -and -not $present) {
    try {
        Remove-AdfsNativeClientApplication `
            -TargetIdentifier $module.Result.application_identifier `
            -Confirm:$false `
            -WhatIf:$module.CheckMode
    }
    catch {
        $module.FailJson("Failed to remove native client application.", $_)
    }

    $module.Result.changed = $true
    $module.ExitJson()
}

# Check if anything must be changed
if (
    ($module.Params.description -and ($adfsNativeClientApplication.Description -ne $module.Params.description)) -or
    ($module.Params.name -and ($adfsNativeClientApplication.Name -ne $module.Params.name)) -or
    (Compare-Object -ReferenceObject $adfsNativeClientApplication.RedirectUri -DifferenceObject $module.Params.redirect_uri)
) {
    # Apply changes
    try {
        Set-AdfsNativeClientApplication `
            -TargetIdentifier $module.Result.application_identifier `
            -Description $module.Params.description `
            -Name $module.Params.name `
            -RedirectUri $module.Params.redirect_uri `
            -WhatIf:$module.CheckMode
    }
    catch {
        $module.FailJson("Failed to modify native client application description.", $_)
    }
    $module.Result.changed = $true
}

$module.ExitJson()
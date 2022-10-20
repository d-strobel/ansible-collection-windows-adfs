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

# Always return group identifier
$module.Result.group_identifier = $module.Params.group_identifier

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
try {
    $nativeApplicationGroup = Get-AdfsNativeApplicationGroup -ApplicationGroupIdentifier $module.Params.group_identifier -ErrorAction SilentlyContinue
}
catch {
    $module.FailJson("Failed to find a native application group '$($module.Params.name)'.", $_)
}


# Check description
if ($module.Params.description -and ($applicationGroup.Description -ne $module.Params.description)) {
    try {
        Set-AdfsNativeClientApplication `
            -TargetApplicationGroupIdentifier $module.Params.group_identifier `
            -Description $module.Params.description `
            -WhatIf:$module.CheckMode
    }
    catch {
        $module.FailJson("Failed to modify native application group description.", $_)
    }
    $module.Result.changed = $true
}

# Check name
if ($module.Params.name -and ($applicationGroup.Name -ne $module.Params.name)) {
    try {
        Set-AdfsNativeClientApplication `
            -TargetApplicationGroupIdentifier $module.Params.group_identifier `
            -Name $module.Params.name `
            -WhatIf:$module.CheckMode
    }
    catch {
        $module.FailJson("Failed to modify native application group name.", $_)
    }
    $module.Result.changed = $true
}

# Check Redirect Uri
if($null -eq $applicationGroup.RedirectUri -and $present){
    try {
        Set-AdfsNativeClientApplication `
            -TargetApplicationGroupIdentifier $module.Params.group_identifier `
            -RedirectUri $module.Params.redirect_uri `
            -WhatIf:$module.CheckMode
    }
    catch {
        $module.FailJson("Failed to set native application group redirect uri.", $_)
    }
}


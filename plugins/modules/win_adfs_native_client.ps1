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





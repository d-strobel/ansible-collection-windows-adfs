#!powershell

# Copyright: (c) 2022, Dustin Strobel (@d-strobel), Yasmin Hinel (@seasxlticecream)
# GNU General Public License v3.0+ (see LICENSE or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell Ansible.ModuleUtils.AddType
#AnsibleRequires -PowerShell ansible_collections.d_strobel.windows_adfs.plugins.module_utils.Helper

$spec = @{
    options             = @{
        group_identifier       = @{ type = "str"; required = $true }
        name                   = @{ type = "str" }
        description            = @{ type = "str" }
        state                  = @{ type = "str"; choices = "absent", "present"; default = "present" }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec, @(Get-AdfsTransformRulesSpecs; Get-AdfsAccessControlPolicySpecs))

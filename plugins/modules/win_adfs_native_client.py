#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2022, Dustin Strobel (@d-strobel), Yasmin Hinel (@seasxlticecream)
# GNU General Public License v3.0+ (see LICENSE or https://www.gnu.org/licenses/gpl-3.0.txt)

DOCUMENTATION = r'''
---
module: win_adfs_native_client
short_description:
description:
-
options:
  state:
    description:
    - Set to C(present) to ensure the application group is present.
    - Set to C(absent) to ensure the application group is removed.
    - Set to C(change) to ensure the application group is present but should get changed.
    type: str
    default: present
    choices: [ absent, present, change ]
  group_identifier:
    description:
    - The identifier of the application group.
    type: str
    required: yes
  name:
    description:
    - The name of the application group.
    type: str
  description:
    description:
    - The description for the application group.
    type: str
  redirect_uri:
    description:
    - XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    type: list
  logout_uri:
    description:
    - XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    type: str
author:
- Dustin Strobel (@d-strobel)
- Yasmin Hinel (@seasxlticecream)
'''

EXAMPLES = r'''
- name: Ensure native application group is present
  d_strobel.windows_adfs.win_adfs_native_client:
    group_identifier: test_group
    state: present
- name: Create a native application group
  d_strobel.windows_adfs.win_adfs_native_client:
    group_identifier: test_group
    name: Test Group
    description: Test description
    redirect_uri:
      - https://example.de
      - https://example.com
    logout_uri: https://example.com/logout
    state: present
- name: Remove native application group test_group
  d_strobel.windows_adfs.win_adfs_native_client:
    group_identifier: test_group
    state: absent
- name: Set the description of the native application group
  d_strobel.windows_adfs.win_adfs_native_client:
    group_identifier: test_group
    description: Managed by XXX
    state: present
- name: Set the redirect uri to the native application group
  d_strobel.windows_adfs.win_adfs_native_client:
    group_identifier: test_group
    redirect_uri:
      - https://example.de
      - https://example.com
    state: present
'''
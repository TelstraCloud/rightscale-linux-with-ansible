#!/bin/bash
# ---
# RightScript Name: Nginx install - Ansible
# Description: Installs basic Ansible Nginx role
# Inputs: {}
# Attachments:
# - setup-nginx.yml
# ...

ansible-galaxy install nginxinc.nginx
ansible-playbook setup-nginx.yml

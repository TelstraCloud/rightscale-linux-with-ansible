# Linux Server with Ansible

Example RightScale CAT that deploys Nginx using Ansible on an Ubuntu Linux server

# Dependencies
Server Template: "RightLink 10.6.0 Linux Base", revision: 102
Multi Cloud Image "Ubuntu_14.04_x64", revision: 70

# Installation

- Install the dependencies in RightScale
- Install right_st (https://github.com/rightscale/right_st) and configure to your account
- Use right_st to upload the two RightScripts
```
right_st rightscript upload Ansible_Client_Install.sh
right_st rightscript upload Nginx_install-Ansible.sh
```
- Upload the CAT into the Self-Service Designer
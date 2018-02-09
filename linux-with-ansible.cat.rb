#Copyright 2018 Telstra
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.


#RightScale Cloud Application Template (CAT)

# DESCRIPTION
# Deploys a basic Ubuntu Linux server and executes Ansible scripts

# Required prolog
name 'Linux Server with Ansible'
rs_ca_ver 20131202
short_description "![Ansible](https://major.io/wp-content/uploads/2014/08/image-ansible.png =64x64)"
long_description "Provisions an Ubuntu Linux server to AWS and then uses Ansible for application provisioning\n
A security group is created to enable SSH access.\n
SSH can be performed using the public/private key stored in your RightScale user profile\n
using the username also stored in your profile."

################################
# Outputs returned to the user #
################################
output "app_link" do
  label "Application Link"
  category "Output"
  description "Follow this URL to view the application running on the server."
end

output "ssh_link" do
  label "SSH Link"
  category "Output"
  description "Use this string to access your server vi SSH."
end

############################
# RESOURCE DEFINITIONS     #
############################

### Server Definition ###
resource "linux_server", type: "server" do
  name first(split(@@deployment.name, last(split(@@deployment.name, /^[^-]+/))))
  cloud "EC2 ap-southeast-2"
  instance_type "t2.micro"
  server_template_href find("RightLink 10.6.0 Linux Base", revision: 102)
  multi_cloud_image_href find("Ubuntu_14.04_x64", revision: 70)
  security_group_hrefs @sec_group
end

resource "sec_group", type: "security_group" do
  name join(["LinuxServerSecGrp-",last(split(@@deployment.href,"/"))])
  description "Linux Server security group."
  cloud "EC2 ap-southeast-2"
end
  
resource "sec_group_rule_ssh", type: "security_group_rule" do
  name join(["Linux server SSH Rule-",last(split(@@deployment.href,"/"))])
  description "Allow SSH access."
  source_type "cidr_ips"
  security_group @sec_group
  protocol "tcp"
  direction "ingress"
  cidr_ips "0.0.0.0/0"
  protocol_details do {
    "start_port" => "22",
    "end_port" => "22"
  } end
end

resource "sec_group_rule_http", type: "security_group_rule" do
  name join(["Linux server HTTP Rule-",last(split(@@deployment.href,"/"))])
  description "Allow HTTP access."
  source_type "cidr_ips"
  security_group @sec_group
  protocol "tcp"
  direction "ingress"
  cidr_ips "0.0.0.0/0"
  protocol_details do {
    "start_port" => "80",
    "end_port" => "80"
  } end
end

# Operations
operation "enable" do
  description "Get information once the app has been launched"
  definition "enable"

  # Update the links provided in the outputs.
  output_mappings do {
    $app_link => $app_url,
    $ssh_link => $ssh_cmd,
  } end
end

# RCL workflow
define enable(@linux_server) return $app_url, $ssh_cmd do
  # Find the instance in the deployment
  $server_addr =  @linux_server.current_instance().public_ip_addresses[0]
  $app_url = "http://" + $server_addr
  $ssh_cmd = "ssh -i ~/.ssh/<Private Key> <Login Name>" + "@" + $server_addr

  # run install script for Ansible and then Nginx using Ansible
  # These could be added to the Server Template as an alternative to executing them within this CAT
  call run_script("Ansible Client Install", @linux_server)
  call run_script("Nginx install - Ansible", @linux_server)
end

# Runs a rightscript on the given target node
define run_script($script_name, @target) do
  @script = rs.right_scripts.get(latest_only: true, filter: join(["name==", $script_name]))
  $right_script_href = @script.href
  @task = @target.current_instance().run_executable(right_script_href: $right_script_href, inputs: {})
  if @task.summary =~ "failed"
    raise "Failed to run " + $script_name + " on server, " + @target.href
  end
end
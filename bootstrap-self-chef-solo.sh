#!/bin/bash
set -e

# install chef
if [[ ! -d /opt/chef/embedded ]]; then wget https://omnitruck.chef.io/install.sh -O - | bash -s; fi;
mkdir -p /etc/chef

# setup a recipe for Build Essentials without fetching with git 
# refer: https://github.com/chef-cookbooks/build-essential 
mkdir -p /var/chef/cookbooks/bootstrap/attributes
mkdir -p /var/chef/cookbooks/bootstrap/recipes
mkdir -p /var/chef/cookbooks/bootstrap/resources
wget https://raw.githubusercontent.com/chef-cookbooks/build-essential/master/attributes/default.rb -O /var/chef/cookbooks/bootstrap/attributes/default.rb
wget https://raw.githubusercontent.com/chef-cookbooks/build-essential/master/recipes/default.rb -O /var/chef/cookbooks/bootstrap/recipes/default.rb
wget https://raw.githubusercontent.com/chef-cookbooks/build-essential/master/resources/build_essential.rb -O /var/chef/cookbooks/bootstrap/resources/build_essential.rb

# berkshelf gem and git
echo -e "chef_gem 'berkshelf'\npackage 'git'\n" > /var/chef/cookbooks/bootstrap/recipes/berks.rb

# make an intermediate runlist
echo -e "{\n \"run_list\": [\n   \"bootstrap::default\",\n   \"bootstrap::berks\"\n  ]\n}" > /etc/chef/chef-solo.json

# run chef solo
cd /var/chef && chef-client -j /etc/chef/chef-solo.json -z

# cleanup
rm -r /var/chef/cookbooks/bootstrap
rm /etc/chef/chef-solo.json

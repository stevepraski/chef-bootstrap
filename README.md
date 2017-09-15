# chef-bootstrap

## Simple Solo Mode Chef Bootstrapping (No Chef Server Needed)

## Work In Progress

## WARNING: Used incorrectly, these scripts will modify your system without warning or prompting, possibly in a damaging way

### 'bootstrap-self-chef-solo.sh'
 - designed to be executed within the server to be bootstrapped
 - installs Chef on most supported platforms
 - installs Berkshelf to '/opt/chef/embedded/bin/berks'
 - allows git cloning of arbitrary public cookbooks, subsequent cookbook vendoring, and Chef solo execution within the target server

### 'chef-solo-bootstrap.sh'
 - designed to be executed from a workstation with the Chef development kit (ChefDK) installed
 - requires a 'chef-solo.json' run list and a cookbook
 - vendors and transfers cookbooks and then executes the run list on the target server
 - assumes that the specified SSH user has sudo rights, which is true for most "cloud" servers, but not necessarily for bare metal or private virtual machines.  As a workaround, the 'root' user can be used, especially if a SSH public key is placed in '/root/.ssh/authorized_keys'.  The best practice is to disable the 'root' user login access via SSH after an administration user with sudo rights is added.

#### Vagrant Testing Example for 'chef-solo-bootstrap.sh'
 - make a directory and initiate a vagrant box, increase its memory allocation and start it:
```
mkdir -p vagrant-chef-bootstrap && cd vagrant-chef-bootstrap
vagrant init bento/ubuntu-17.04
sed -i '$ d' Vagrantfile
echo -e  "  config.vm.provider \"virtualbox\" do |vb|\n  vb.memory = \"2048\"\n end\nend" >> Vagrantfile
vagrant up
```
 - clone a cookbook (e.g., from my base-box-cookbook) and make a chef-solo.json:
```
git clone https://github.com/stevepraski/base-box-cookbook.git
cd base-box-cookbook
wget https://raw.githubusercontent.com/stevepraski/chef-bootstrap/master/chef-solo-bootstrap.sh
cat > chef-solo.json << EOL
{
  "authorization": {
    "sudo": {
     "users": ["sysop", "vagrant"]
    }
  },
    "run_list": [
      "base-box-cookbook::default"
  ]
}
EOL

```
 - execute the script, assuming the Vagrant box port is 2222
 - alternatively, and assuming you created the directory structure correctly, add '--sshkey="$(pwd)/../.vagrant/machines/default/virtualbox/private_key"' to use the generated Vagrant private key, and avoid entering the password 'vagrant'
```
bash chef-solo-bootstrap.sh --port=2222 --server=localhost --user=vagrant
```
 - Vagrant Cleanup:
```
cd ../vagrant-chef-bootstrap
vagrant destroy -f

```

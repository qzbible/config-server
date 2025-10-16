# Config-server

A set of Ansible playbooks and scripts to configure a server for dbn.

## Dependencies and prerequisites

### The composite action `setup-ansible`

There is a [composite action](https://docs.github.com/fr/actions/creating-actions/creating-a-composite-action) located
at [setup-ansible](.github/actions/setup-ansible) that contains the ansible configuration:

- [group_vars](.github/actions/setup-ansible/config/group_vars): Variables for all hosts
- [ansible.cfg](.github/actions/setup-ansible/config/ansible.cfg): Ansible CLI configuration
- [inventory.yml](.github/actions/setup-ansible/config/inventory.yml): The inventory file containing the list of servers
- [requirements.yml](.github/actions/setup-ansible/config/requirements.yml): Ansible roles and collections to install.

The main purpose of this action is to be used in GitHub Actions by this repo and other repos in the GitHub organization.
The idea is to share the same Ansible configurations here and there.

## Initial Configuration of a new server

Before using Ansible, here are a few things to do:

1. Change the SSH default port. Connect to the serveur and edit the file `/etc/ssh/sshd_config`. There is a commented
   line `#Port 22`. Change it to `Port 2209` (or something else). Restart `sshd` service: `sudo systemctl restart sshd` or `sudo systemctl restart ssh`.
2. Connect to the server and upload your SSH public key to the default user. We will disable login via password later
   one.
3. Make sure you can connect via your SSH private key before moving on.

The playbooks in this repo are focused on Debian based distributions. Once you got a new serveur, add its information
into the [inventory.yml](./inventory.yml) file similar to the existing hosts.

## The playbooks

The playbook names usually define the order in which to run them to configuration a new server. Not all playbook apply
to servers.

- [01-base.yml](01-base.yml): Security related settings about SSH and some common settings and packages to apply to all
  servers owned by dbn.
- [10-docker.yml](10-docker.yml): Install Docker, init docker Swarm, crontab to prune Docker everyday
- [11-stack-reverse-proxy.yml](11-stack-reverse-proxy.yml): Install the reverse-proxy (Traefik). The password for the
  user is available in the vault file. See below how to read the vault.
- [12-stack-portainer.yml](12-stack-portainer.yml): Install portainer. Once installed, you need to access it ASAP to
  set the admin user and password.
- [13-postgresql.yml](13-postgresql.yml): Install PostgreSQL to be used by the different instances of dbn. Once
  installed, perform the following actions:
    - Set a password for the default user `postgres` by
      running `sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'new_password';"`. The current password for this
      user is in the vault file: `vault_postgres_admin_user_password`.
    - Block connection to
      the `postgres` database: `sudo -u postgres psql -c "REVOKE connect ON DATABASE postgres FROM PUBLIC;"`. Only
      the use `postgres` should have to this table.
    - You need to create the databases and users for instance of dbn. See the [README](./postgres-databases/README.md)
      in the `postgres-databases` folder.

## How to run a playbook locally

1. Make sure you have the relevant SSH keys on our machine that have access to the servers in the inventory file.
2. Create symbolic links for the files in [.github/actions/setup-ansible/config](.github/actions/setup-ansible/config)
   in the root dir:
    - `ln -s .github/actions/setup-ansible/config/group_vars .`
    - `ln -s .github/actions/setup-ansible/config/ansible.cfg .`
    - `ln -s .github/actions/setup-ansible/config/requirements.yml .`
    - `ln -s .github/actions/setup-ansible/config/inventory.yml .`
3. You need the ansible vault password. Create the file `.vault_pass` and put the password in it. Ask for the vault
   password.
4. Run this to test the connection to the serveur `ansible -m setup all`. This command will gather and display some
   metadata for **all** servers in the inventory file.
5. Installer les rôles requis avec le fichier requirements.yml `ansible-playbook -i inventory.yml requirements.yml`
6. Spécifier explicitement l'adresse IP `ssh ovh_manager` `docker swarm init --advertise-addr $(ip -4 addr show ens3 | grep inet | awk '{print $2}' | cut -d'/' -f1 | head -1)`
6. To run a playbook a specific host (in this case the `ovh_manager`): `ansible-playbook 10-docker.yml --limit ovh_manager`

## How to read the vault

The vault file is encrypted. To read it, you need the vault password. Create the file `.vault_pass` and put the password
in it. Then run this command: `ansible-vault view group_vars/all/vault`

To edit the vault, run `ansible-vault edit group_vars/all/vault`.

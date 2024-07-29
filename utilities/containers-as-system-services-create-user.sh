#!/bin/bash
# containers-as-system-services.sh 

# Guided Exercise 3: Manage Containers as System Services
# Student Guide Notes and Commands
# You should practice by running these commands one by one on your terminal
# ... they help you follow or understand the steps in the student guide.
# But of course you can run it as a script in one go ... just to see it do its
# magic.

# Approximate reference to the Guided Exercise text is included as comments (eg #5.0.).

# Preparation
echo '********* PREPARATION *************'
# **** First, create the required user account, with sudo privilege and login/ssh into it

# 2.
echo '2. **Creating a user account with which to run the Systemd user service ***'
sudo useradd contsvc 2>/dev/null
echo User contsvc created ...  ok

echo redhat | sudo passwd contsvc --stdin 2>/dev/null
echo User contsvc pasword: redhat ... ok

# Make the new user a sudoer
echo 'contsvc ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/contsvc
echo User contsvc given password-less sudo ... ok

# 2.2
echo -e "\n **** Now login as user contsvc. You can use ssh/Putty  *****"
echo "IP Info:"
ip -br a
echo -e "\n **** Then continue the exercise there.  *****"
echo -e "\n******** FINISHED ***************\n"

# Relogin as user contsvc (required to use podman). Let's ssh instead
# First: quietly install sshpass; we need it for non-interactive 
# password-based login in this script :)
dnf -q install -y sshpass 2>/dev/null
# sshpass -p redhat ssh -Tqo StrictHostKeyChecking=no -o PasswordAuthentication=yes contsvc@localhost

# Now continue as user contsvc. For guidance, see the script:
# containers-as-system-services-contsvc.sh

# ******   FINISHED   ******

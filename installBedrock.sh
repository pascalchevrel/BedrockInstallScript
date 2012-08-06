#! /bin/bash

echo "BEDROCK installation script on Linux"
echo "Warning: This install script works on Ubuntu 12.04, it hasn't been tested on anything else."
echo "Warning: There is no error handling whatsoever."
echo "Feel free to fork it for another distro or to add your changes"
echo "This script is going to install Bedrock in a bedrock folder."
echo "We assume that you have recently forked bedrock on github and will use that as a basis."
echo "If you are in a Virtual Machine, don't forget to add your ssh key on it"
echo "Please provide your github user name below: "
read repo
echo "Sudo mode, install Node.js, Subversion, Git, npm, virtualenv. (if they were not already installed)"
#sudo apt-get install subversion git nodejs npm python-virtualenv python-jinja2 python-bcrypt
sudo apt-get install subversion git nodejs npm python-virtualenv python-dev
echo "git@github.com:${repo}/bedrock.git"
git clone --recursive git@github.com:${repo}/bedrock.git
#git clone --recursive https://${repo}@github.com/${repo}/bedrock.git
cd ./bedrock
git remote add upstream git://github.com/mozilla/bedrock.git
echo "Sudo mode, install Bedrock dependencies"
echo "Create a virtual environement in the folder venv"
virtualenv venv                            # create a virtual env in the folder `venv`
echo "activate the virtual env"
source venv/bin/activate                   # activate the virtual env
echo "Install Bedrock dependencies"
./venv/bin/pip install -r requirements/compiled.txt   # installs compiled dependencies
#./venv/bin/pip install -r requirements/dev.txt   # installs dev dependencies
echo "Install Bedrock dependencies"
./venv/bin/pip install jinja2 django-bcrypt
echo "Copy settings/local.py-dist into settings/local.py"
cp settings/local.py-dist settings/local.py
echo "Check out the latest product-details"
./manage.py update_product_details
echo "Install the less compiler"
sudo npm install -g less
echo -e "\nLESS_BIN = '/usr/local/bin/lessc'" >> settings/local.py
#echo 'ROOT_URLCONF = "urls"' >> settings/local.py
echo "Check out all the translation which live on svn in the localizers repository"
mkdir locale
cd locale
svn co https://svn.mozilla.org/projects/mozilla.com/trunk/locales/ .


#! /bin/bash

echo "BEDROCK installation script on Linux"
echo "Warning: This install script works on Ubuntu 12.10 (64bits), it should work on 12.04, but it hasn't been tested on anything else."
echo "Warning: There is no error handling whatsoever."
echo "Feel free to fork it for another distro or to add your changes"
echo "This script is going to install Bedrock in a bedrock folder."
echo "We assume that you have recently forked bedrock on github and will use that as a basis."
echo "If you are in a Virtual Machine, don't forget to add your ssh key on it"
echo "Please provide your github user name below: "
read repo

echo "Do you need to install subversion git nodejs npm python-virtualenv python-dev (sudo password needed)? (y/n)"
read -n 1 globaldependencies
echo ""
if [ $globaldependencies == 'y' ]
then
    echo "Sudo mode, install Node.js, Subversion, Git, npm, virtualenv. (if they were not already installed)"
    sudo apt-get install subversion git nodejs npm python-virtualenv python-dev libxml2-dev libxslt1-dev node-less
    ./venv/bin/pip install -r requirements/dev.txt   # installs dev dependencies
fi

echo "git@github.com:${repo}/bedrock.git"
git clone --recursive git@github.com:${repo}/bedrock.git
#git clone --recursive https://${repo}@github.com/${repo}/bedrock.git

cd ./bedrock

echo "git://github.com/mozilla/bedrock.git added as upstream remote "
git remote add upstream git://github.com/mozilla/bedrock.git

echo "Create a virtual environement in the folder venv"
virtualenv venv                            # create a virtual env in the folder `venv`
echo "Activate the virtual env"
source venv/bin/activate                   # activate the virtual env
echo "Install Bedrock local dependencies in venv"
./venv/bin/pip install -r requirements/compiled.txt   # installs compiled dependencies

echo "Do you want to install developper dependencies to be able to run tests locally and participate to documentation? (y/n)"
read -n 1 devdependencies
echo ""
if [ $devdependencies == 'y' ]
then

    echo "Installing developer dependencies..."
    ./venv/bin/pip install -r requirements/dev.txt   # installs dev dependencies
fi

echo "Install more Bedrock dependencies"
./venv/bin/pip install jinja2 django-bcrypt

echo "Copy settings/local.py-dist into settings/local.py"
cp settings/local.py-dist settings/local.py

echo "Check out the latest product-details"
./manage.py update_product_details

echo -e "\nLESS_BIN = '/usr/bin/lessc'" >> settings/local.py

echo "Check out all the translations which live on svn in the localizers repositories"

mkdir locale
cd locale
svn co https://svn.mozilla.org/projects/mozilla.com/trunk/locales/ .


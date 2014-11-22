#! /bin/bash

set -o errexit

echo "BEDROCK installation script on Linux"
echo "Warning: This install script works on Ubuntu 13.04 (64bits)"
echo "Warning: There is no error handling whatsoever."
echo "Feel free to fork it and adapt it for another distro or update your changes"
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
    sudo apt-get update
    sudo apt-get install -y subversion git nodejs npm python-virtualenv python-dev libxml2-dev libxslt1-dev node-less
fi

echo "git@github.com:${repo}/bedrock.git"
git clone --recursive git@github.com:${repo}/bedrock.git

cd ./bedrock

echo "git://github.com/mozilla/bedrock.git added as upstream remote "
git remote add upstream git://github.com/mozilla/bedrock.git

echo "Create a virtual environement in the folder venv"
virtualenv venv                                         # create a virtual env in the folder `venv`
echo "Activate the virtual env"
source venv/bin/activate                                # activate the virtual env
echo "Install Bedrock local dependencies in venv"
./venv/bin/pip install -r requirements/compiled.txt     # installs compiled dependencies

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

echo "Copy bedrock/settings/local.py-dist into bedrock/settings/local.py"
cp bedrock/settings/local.py-dist bedrock/settings/local.py

echo "Sync database schemas"
./bin/sync_all


sudo pip uninstall -y django    # included as submodule, we do not want the one installed by django-nose requirements
sudo pip install ipython        # highly recommended, but not required so not in requirements/dev.txt

echo "npm install: less, grunt-cli, jshint"
npm install -g less
npm install -g grunt-cli
npm install -g jshint
npm install
#echo -e "\nLESS_BIN = '/usr/bin/lessc'" >> bedrock/settings/local.py

echo "Check out all the translations which live on svn in the localizers repositories"

# ln -s ~/repos/svn/mozillaorg/trunk/locales/ locale
mkdir locale
cd locale
svn co https://svn.mozilla.org/projects/mozilla.com/trunk/locales/ .

echo "start mysql"
mysql-ctl start

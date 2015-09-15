#! /bin/bash

set -o errexit

# Pretty printing functions
NORMAL=$(tput sgr0)
GREEN=$(tput setaf 2; tput bold)
RED=$(tput setaf 1)

function echored() {
    echo -e "$RED$*$NORMAL"
}

function echogreen() {
    echo -e "$GREEN$*$NORMAL"
}

echogreen "BEDROCK installation script on Ubuntu"
echo "Warning: This install script works on Ubuntu 14.10 and 15.04 (64bits)"
echo "Warning: There is no error handling whatsoever."
echo "Feel free to fork it and adapt it for another distro or update your changes"
echo "This script is going to install Bedrock in a bedrock folder."
echo "We assume that you have recently forked bedrock on github and will use that as a basis."
echo "If you are in a Virtual Machine, don't forget to add your ssh key on it or choose https for repository cloning."

echored "Please provide your github user name below: "
read repo

if [ -z "$repo" ]
then
    repo="pascalchevrel"
fi

echored "Do you use GitHub via HTTPS? (y/n)"
read -n 1 https
echo ""

echored "Do you need to install subversion git nodejs npm python-virtualenv python-dev (sudo password needed)? (y/n)"
read -n 1 globaldependencies
echo ""
if [ $globaldependencies == 'y' ]
then
    echo "Sudo mode, install Node.js, Subversion, Git, npm, virtualenv. (if they were not already installed)"
    sudo apt-get update
    sudo apt-get install -y subversion git nodejs python-virtualenv python-dev libxml2-dev libxslt1-dev node-less nodejs-legacy
fi

echogreen "Cloning Bedrock locally"
if [ -d "bedrock/.git" ]
then
    echored "Repository already cloned"
else
    if [ $https == 'y' ]
    then
        echogreen "Repository: https://github.com/${repo}/bedrock.git"
        git clone --recursive https://github.com/${repo}/bedrock.git
    else
        echogreen "Repository: git@github.com:${repo}/bedrock.git"
        git clone --recursive git@github.com:${repo}/bedrock.git
    fi
fi

cd ./bedrock
if git remote | grep upstream > /dev/null
then
    echored "Upstream remote is alteady set"
else
    if [ $https == 'y' ]
    then
        echogreen "https://github.com/mozilla/bedrock.git added as upstream remote"
        git remote add upstream https://github.com/mozilla/bedrock.git
    else
        echogreen "git://github.com/mozilla/bedrock.git added as upstream remote "
        git remote add upstream git://github.com/mozilla/bedrock.git -f
    fi
fi

echogreen "Get latest commits from upstream Bedrock"
git pull upstream master
git submodule update --init --recursive

echogreen "Create a virtual environement in the folder venv"
virtualenv -p python2.7 venv   # create a virtual env in the folder `venv`
echo "Activate the virtual env"
source ./venv/bin/activate    # activate the virtual env
echogreen "Install Bedrock local dependencies in venv"
./venv/bin/pip install -r requirements/pip.txt
./bin/peep.py install -r requirements/dev.txt

echored "Do you want to install npm dependencies globally (sudo needed)? (y/n)"
read -n 1 npmdependencies
echo ""
if [ $npmdependencies == 'y' ]
then
    echogreen "npm install: less, grunt-cli, jshint"
    sudo npm install -g less
    sudo npm install -g grunt-cli
    sudo npm install -g jshint
    sudo npm install
fi

echogreen "Copy bedrock/settings/local.py-dist into bedrock/settings/local.py"
cp bedrock/settings/local.py-dist bedrock/settings/local.py
sed -i -- "s/STATSD_HOST = ''/STATSD_HOST = 'localhost'/g" bedrock/settings/local.py

find . -name '*.pyc' -exec rm {} \;

echogreen "Check out all the translations which live on svn in the localizers repositories"
# ln -s ~/repos/svn/mozillaorg/trunk/locales/ locale
mkdir locale
cd locale
svn co https://svn.mozilla.org/projects/mozilla.com/trunk/locales/ .


echogreen "Sync database schemas"
cd ..
./bin/sync_all


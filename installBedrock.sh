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
echo "Warning: This install script works on Ubuntu 16.04 (64bits), just because that's what I tested it on"
echo "Warning: There is no error handling whatsoever."
echo "Feel free to fork it and adapt it for another distro or update your changes"
echo "This script is going to install Bedrock in a bedrock folder."
echo "We assume that you have recently forked Bedrock on GitHub and will use that as a basis."
echo "If you are in a Virtual Machine, don't forget to add your ssh key on it or choose https for repository cloning."

echored "Please provide your GitHub user name below:"
read repo

if [ -z "$repo" ]
then
    repo="pascalchevrel"
fi

echored "Do you use GitHub via HTTPS? (y/n)"
read -n 1 https
echo ""

echored "Do you need to install git nodejs npm python-virtualenv python-dev (sudo password needed)? (y/n)"
read -n 1 globaldependencies
echo ""
if [ $globaldependencies == 'y' ]
then
    echored "Sudo mode: install Git, nodejs, npm, virtualenv (if they were not already installed)"
    sudo apt-get update
    sudo apt-get install -y git python-virtualenv python-dev libxml2-dev libxslt1-dev npm nodejs
fi

echogreen "Cloning Bedrock locally"
if [ -d "bedrock/.git" ]
then
    echored "Repository already cloned"
else
    git_repo="git@github.com:${repo}/bedrock.git"
    if [ $https == 'y' ]
    then
        git_repo="https://github.com/${repo}/bedrock.git"
    fi
    echogreen "Repository: ${git_repo}"
    git clone --recursive $git_repo
fi

cd ./bedrock
if git remote | grep upstream > /dev/null
then
    echored "Upstream remote is already set"
else
    if [ $https == 'y' ]
    then
        echogreen "https://github.com/mozilla/bedrock.git added as upstream remote"
        git remote add upstream https://github.com/mozilla/bedrock.git
    else
        echogreen "git://github.com/mozilla/bedrock.git added as upstream remote "
        git remote add upstream git://github.com/mozilla/bedrock.git
    fi
fi

echogreen "Get latest commits from upstream Bedrock"
git pull upstream master
git submodule update --init --recursive

echogreen "Create a virtual environement in the venv_bedrock folder"
virtualenv -p python2.7 venv_bedrock
echo "Activate the virtual environment"
source ./venv_bedrock/bin/activate

echogreen "Install Bedrock local dependencies in venv_bedrock"
python ./bin/pipstrap.py
./venv_bedrock/bin/pip install -r requirements/dev.txt

echored "Installation of npm dependencies in the project"
echored "We first create this symlink needed for Debian based distros:"
echored "sudo ln -sf /usr/bin/nodejs /usr/bin/node"
sudo ln -sf /usr/bin/nodejs /usr/bin/node
npm install

echogreen "Copy .env-dist into .env"
cp .env-dist .env

echogreen "Check out all the translations which live in a separate github repo"
if [ ! -d "locale" ]
then
    git clone --depth=1 https://github.com/mozilla-l10n/www.mozilla.org locale
else
    cd locale
    echogreen "Update translations"
    git pull
    cd ..
fi

echogreen "Sync database schemas (this step takes a looooong time...)"
./bin/sync_all

echo "Deactivate the virtual environment"
deactivate

echogreen "Bedrock is now installed, enter your bedrock folder, activate your virtual enronment and run gulp, ehre are the commands:"
echogreen "cd bedrock"
echogreen "source ./venv_bedrock/bin/activate"
echogreen "./node_modules/gulp/bin/gulp.js"

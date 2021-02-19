#!/bin/bash

#error function.
#print $1 in red and exit with exit code 1.
#example usage: error "Failed to do something!"
function error() {
	echo -e "\e[91m$1\e[39m"
 	exit 1
}

#update function (to check for updates)
function updater() {
	echo "Checking for updates..."
	localhash="$(git rev-parse HEAD)"
	latesthash="$(git ls-remote https://github.com/Itai-Nelken/box86-2deb-weekly-script HEAD | awk '{print $1}')"

if [ "$localhash" != "$latesthash" ] && [ ! -z "$latesthash" ] && [ ! -z "$localhash" ];then
    echo "Out of date, updating now..."
    git clean -fd
    git reset --hard
    git pull https://github.com/Itai-Nelken/box86-2deb-weekly-script.git HEAD || error 'Unable to update, please check your internet connection'
else
    echo "Up to date."
fi
}

#check that script isn't being run as root.
if [ "$EUID" = 0 ]; then
  error "You cannot run this script as root!"
fi

#get current directory and assign it to the 'DIR' variable
DIR="`pwd`"
#check that script is being run from the correct directory
if [[ ! $DIR == "$HOME/Documents/box86-2deb-weekly-script" ]]; then
    error "script isn't being run from $HOME/Documents/box86-2deb-weekly-script'!\nplease read the readme for usage instructions."
else
    echo -e "script is being run from correct directory $(tput setaf 2)✔︎$(tput sgr 0)"
fi

#about flag.
#usage: ./start.sh --about
if [[ "$1" == "--about" ]]; then
	#echo "script by Itai-Nelken"
	echo "a script that automatically compiles and packages box86"
	echo "into a deb using checkinstall."
    cat credits
    exit 0
elif [[ $1 == "--update" ]]; then
    updater
    sudo chmod +x start.sh
    exit 0
fi

#check that OS arch is armhf
ARCH="`uname -m`"
if [[ $ARCH == "armv7l" ]] || [[ $ARCH == "arm64" ]] || [[ $ARCH == "aarch64" ]]; then
    if [ ! -z "$(file "$(readlink -f "/sbin/init")" | grep 64)" ];then
        error "This script doesn't work on arm64!"
    elif [ ! -z "$(file "$(readlink -f "/sbin/init")" | grep 32)" ];then
        echo -e "arch is armhf/armv7l $(tput setaf 2)✔︎$(tput sgr 0)"
    else
        error "Failed to detect OS CPU architecture! Something is very wrong."
    fi
fi

#check that checkinstall is installed, if not ask to install it.
if ! command -v checkinstall >/dev/null ; then
    read -p "checkinstall is required but not installed, do you want to install it? (y/n)?" choice
    case "$choice" in 
    y|Y|yes|YES ) check=1;;
    n|N|no|NO ) echo "can't continue without checkinstall! exiting in 10 seconds"; sleep 10; exit 1;;
    * ) echo "invalid";;
    esac
else
	echo -e "checkinstall is installed $(tput setaf 2)✔︎$(tput sgr 0)"
fi
if [[ $check == "1" ]]; then
    wget https://archive.org/download/macos_921_qemu_rpi/checkinstall_20210123-1_armhf.deb -O $HOME/checkinstall_20210123-1_armhf.deb
    sudo apt -f -y install ~/checkinstall_20210123-1_armhf.deb
    rm -f ~/checkinstall_20210123-1_armhf.deb
fi

#check that '~/Documents/box86-auto-build' (and '~/Documents/box86-auto-build/debs') exist.
if [[ ! -d "$HOME/Documents/box86-auto-build" ]]; then
    echo -e "'$HOME/Documents/box86-auto-build' doesn't exist! $(tput setaf 1)❌$(tput sgr 0)"
    echo "creating it..."
    mkdir -p $HOME/Documents/box86-auto-build/debs
    echo -e "done! $(tput setaf 2)✔︎$(tput sgr 0)"
else
    echo -e "'$HOME/Documents/box86-auto-build' exists $(tput setaf 2)✔︎$(tput sgr 0)"
fi

#check if main script is executable, if no make it executable.
if [[ -x "$DIR/box86-2deb-auto.sh" ]]; then
	echo -e "script is executable $(tput setaf 2)✔︎$(tput sgr 0)"
else
	echo -e "script isn't executable! $(tput setaf 1)❌$(tput sgr 0)"
	echo "making script executable..."
	sudo chmod +x box86-2deb-auto.sh || error "Failed to mark script as executable!"
	echo -e "done! $(tput setaf 2)✔︎$(tput sgr 0)"
fi
./box86-2deb-auto.sh || error "Failed to start script!"


#######CHECK THAT start.sh ISN'T BEING RUN AS ROOT#######################

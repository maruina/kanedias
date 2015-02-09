#!/bin/bash
set -e

install_folder=$HOME
cd ${install_folder}

sudo apt-get update
sudo apt-get -y upgrade

# Install Desktop Environment
sudo apt-get install ubuntu-desktop
sed -i 's/allowed_users=.*/allowed_users=anybody/g' /etc/X11/Xwrapper.config

# Install pre-requisites
sudo apt-get install -y g++-4.7 git-core automake libexpat1-dev python-matplotlib python-serial python-wxgtk2.8 python-lxml python-scipy python-opencv ccache gawk git python-pip python-pexpect
sudo pip install pymavlink MAVProxy

export PATH=$PATH:$HOME/copter-stable/Tools/autotest
export PATH=$PATH:/usr/local/lib/python2.7/dist-packages/MavProxy
export PATH=$PATH:/usr/local/lib/python2.7/dist-packages/pymavlink/examples
export PATH=/usr/lib/ccache:$PATH

echo 'export PATH=$PATH:$HOME/copter-stable/Tools/autotest' >> ~/.bashrc
echo 'export PATH=$PATH:/usr/local/lib/python2.7/dist-packages/MavProxy' >> ~/.bashrc
echo 'export PATH=$PATH:/usr/local/lib/python2.7/dist-packages/pymavlink/examples' >> ~/.bashrc
echo 'export PATH=/usr/lib/ccache:$PATH' >> ~/.bashrc
. ~/.bashrc

# Install SITL
git clone -b Copter-stable --single-branch git://github.com/virtualrobotix/ardupilot.git copter-stable
cd copter-stable/ArduCopter
make configure
echo 'ARMING_CHECK 0' >> ${install_folder}/copter-stable/Tools/autotest/copter_params.parm

sudo reboot
#!/bin/sh

install_folder=/home/vagrant

sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get install -y g++-4.7 git-core automake libexpat1-dev

mkdir ${install_folder}/ardupilot
git clone git://github.com/diydrones/ardupilot.git ${install_folder}/ardupilot
chmod +x ${install_folder}/ardupilot/Tools/scripts/install-prereqs-ubuntu.sh
${install_folder}/ardupilot/Tools/scripts/install-prereqs-ubuntu.sh

echo 'export PATH=$PATH:$HOME/ardupilot/Tools/autotest' >> ~/.bashrc
echo 'export PATH=$PATH:/usr/local/lib/python2.7/dist-packages/MavProxy' >> ~/.bashrc
echo 'export PATH=$PATH:/usr/local/lib/python2.7/dist-packages/pymavlink/examples' >> ~/.bashrc
echo 'export PATH=/usr/lib/ccache:$PATH' >> ~/.bashrc
. ~/.bashrc
cd ${install_folder}/ardupilot/ArduCopter
make configure

echo 'ARMING_CHECK 0' >> ${install_folder}/ardupilot/Tools/autotest/copter_params.parm
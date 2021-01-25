set -e

echo -e "\nInit"
apt update
apt-get -o Dpkg::Options::='--force-confold' --force-yes -fuy dist-upgrade

apt install -y python3-pip

echo -e "\nInstall Tailon"
pip3 install tailon

echo -e "\nRun Tailon"
nohup tailon -p basic -u admin:whenguardian2021 -b 0.0.0.0:9999 -f /var/log/*/* &
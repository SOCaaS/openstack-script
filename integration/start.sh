set -e

echo -e "\nInit"
apt update
apt upgrade -y
apt install -y python3-pip

echo -e "\nInstall Tailon"
pip3 install tailon

echo -e "\nRun Tailon"
nohup tailon -p basic -u admin:whenguardian2021 -b 0.0.0.0:9098 -f /var/log/ &
set -e

echo -e "\nInit"
apt update

apt install -y python3-pip

echo -e "\nInstall Tailon"
pip3 install tailon

echo -e "\nCopy Tailon Settings"
cp ./system/tailon.service /etc/systemd/system/tailon.service


echo -e "\nReload Daemon"
systemctl daemon-reload

systemctl start tailon.service
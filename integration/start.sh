echo -e "\nInstall Tailon"
pip install tailon

echo -e "\nRun Tailon"
nohup tailon -p basic -u admin:whenguardian2021 -b 0.0.0.0:9098 -f /var/log/ &
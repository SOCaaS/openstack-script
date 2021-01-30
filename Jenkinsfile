pipeline {
    agent none 
    options {
        ansiColor('xterm')
    }
    stages {
        stage('Create / Delete') {
            agent {
                docker {
                    image 'base/terraform:latest'
                    args  '-v /root/tfstate:/root/tfstate -v /root/tfvars:/root/tfvars'
                }
            }
            steps {
                echo 'Terraform Creating Server'
                sh 'terraform --version'
                dir("deployment") {
                    sh '''#!/bin/bash
                        terraform init
                        terraform plan  -var-file=/root/tfvars/do-contabo.tfvars
                        terraform apply -var-file=/root/tfvars/do-contabo.tfvars --auto-approve
                        terraform show
                    '''
                }
                echo 'Finished'
            }
        }
        stage('Rebuild') {
            agent {
                docker {
                    image 'base/digitalocean-doctl:latest' 
                    args  '-v /root/tfstate:/root/tfstate -v /home/ezeutno/.ssh/id_rsa:/root/.ssh/id_rsa'
                }
            }
            steps {
                sh 'ls -lah /root/.ssh'
                sh '''#!/bin/bash
                    if [ $(cat /root/tfstate/script-openstack-do.tfstate | jq \'.["outputs"]["ids"]["value"][0]\') == null ] 
                    then 
                        echo "The server is being turn off!"; 
                    else
                        echo -e "\nDO Re-Build!"
                        doctl compute droplet-action rebuild $(cat /root/tfstate/script-openstack-do.tfstate | jq \'.["outputs"]["ids"]["value"][0]\' | sed \'s|"||g\' ) -t ${DIGITALOCEAN_TOKEN} --image ubuntu-20-04-x64 --wait
                        echo -e "\nPing Finished!"
                        ping -c 10 $(cat /root/tfstate/script-openstack-do.tfstate | jq \'.["outputs"]["ips"]["value"][0]\' | sed \'s|"||g\' )
                        
                        echo -e "\nCopy data to DigitalOcean!"
                        scp -o StrictHostKeyChecking=no -i /root/.ssh/id_rsa -r $PWD root@$(cat /root/tfstate/script-openstack-do.tfstate | jq \'.["outputs"]["ips"]["value"][0]\' | sed \'s|"||g\' ):/root/script-openstack/
                        
                        echo -e "\nStart SSH Script!"
                        ssh -o StrictHostKeyChecking=no -i /root/.ssh/id_rsa root@$(cat /root/tfstate/script-openstack-do.tfstate | jq \'.["outputs"]["ips"]["value"][0]\' | sed \'s|"||g\' ) "cd /root/script-openstack/; ./start.sh"
                    fi 
                '''
                echo 'Finished'
            }
        }
    }
    post {
        success {
            discordSend description: "Openstack CI/CD SUCCESS", footer: "openstack-script-cicd", link: env.BUILD_URL, result: currentBuild.currentResult, title: JOB_NAME, webhookURL: env.DISCORD_WEBHOOK
        }
        failure {
            discordSend description: "Openstack CI/CD Failed", footer: "openstack-script-cicd", link: env.BUILD_URL, result: currentBuild.currentResult, title: JOB_NAME, webhookURL: env.DISCORD_WEBHOOK
        }
    }  
}
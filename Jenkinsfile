pipeline {
    agent none 
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
                    sh 'terraform init'
                    sh 'terraform plan  -var-file=/root/tfvars/do-contabo.tfvars'
                    sh 'terraform apply -var-file=/root/tfvars/do-contabo.tfvars --auto-approve'
                }
                echo 'Finished'
            }
        }
        stage('Rebuild') {
            agent {
                docker {
                    image 'base/digitalocean-doctl:latest' 
                    args  '-v /root/tfstate:/root/tfstate'
                }
            }
            steps {
                sh 'apt update'
                sh 'apt install -y ssh jq'
                sh 'cat /root/tfstate/script-openstack-servers.tfstate.backup | jq ".[\"outputs\"][\"ids\"][\"value\"][0]"'
                // sh 'doctl compute droplet-action rebuild 226306913 -t ${DIGITALOCEAN_TOKEN} --image ubuntu-20-04-x64 --wait'
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
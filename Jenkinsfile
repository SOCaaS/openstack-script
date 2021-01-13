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
                    sh 'terraform plan  -var-file=/root/tfvars/digitalocean.tfvars'
                    sh 'terraform apply -var-file=/root/tfvars/digitalocean.tfvars --auto-approve'
                }
                echo 'Finished'
            }
        }
        stage('Rebuild') {
            agent {
                docker {
                    image 'base/digitalocean-doctl:latest'
                }
            }
            steps {
                sh 'doctl'
                echo 'Finished'
            }
        }
    }
    post {
        success {
            discordSend description: "Openstack CI/CD SUCCESS", footer: "openstack-script-cicd", link: env.BUILD_URL, result: currentBuild.currentResult, title: JOB_NAME, webhookURL: env.SOCAAS_WEBHOOK
        }
        failure {
            discordSend description: "Openstack CI/CD Failed", footer: "openstack-script-cicd", link: env.BUILD_URL, result: currentBuild.currentResult, title: JOB_NAME, webhookURL: env.SOCAAS_WEBHOOK
        }
    }  
}
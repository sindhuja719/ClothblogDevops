pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        ECR_REPO   = '312596057535.dkr.ecr.us-east-1.amazonaws.com/cloth-blog'
        IMAGE_TAG  = "latest"
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/sindhuja719/ClothblogDevops.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                bat "docker build --no-cache -t %ECR_REPO%:%IMAGE_TAG% ."
            }
        }

        stage('Login to ECR') {
            steps {
                withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
                    bat "aws ecr get-login-password --region %AWS_REGION% | docker login --username AWS --password-stdin %ECR_REPO%"
                }
            }
        }

        stage('Push Docker Image to ECR') {
            steps {
                bat "docker push %ECR_REPO%:%IMAGE_TAG%"
            }
        }

        stage('Deploy Infrastructure (Terraform)') {
            steps {
                dir('terraform') {
                    withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
                        bat "terraform init -input=false"
                        bat "terraform apply -auto-approve"
                    }
                }
            }
        }

        stage('Deploy Application on EC2') {
            steps {
                script {
                    // Get EC2 Public IP from Terraform
                    def EC2_IP = bat(
                        script: 'cd terraform && terraform output -raw public_ip',
                        returnStdout: true
                    ).trim()

                    echo "EC2 Public IP: ${EC2_IP}"

                    // SSH using Jenkins stored SSH key
                    sshagent(credentials: ['ec2-ssh-key']) {
                        bat """
                        ssh -o StrictHostKeyChecking=no ec2-user@${EC2_IP} ^
                        "sudo docker stop cloth || true && ^
                        sudo docker rm cloth || true && ^
                        sudo docker rmi %ECR_REPO%:%IMAGE_TAG% || true && ^
                        aws ecr get-login-password --region %AWS_REGION% | sudo docker login --username AWS --password-stdin %ECR_REPO% && ^
                        sudo docker pull %ECR_REPO%:%IMAGE_TAG% && ^
                        sudo docker run -d --name cloth -p 80:80 %ECR_REPO%:%IMAGE_TAG% && ^
                        echo Deployment Successful!"
                        """
                    }
                }
            }
        }

        stage('Destroy Infrastructure (Manual Trigger)') {
            when {
                expression { return params.DESTROY_INFRA == true }
            }
            steps {
                dir('terraform') {
                    withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
                        bat "terraform destroy -auto-approve"
                    }
                }
            }
        }
    }

    parameters {
        booleanParam(name: 'DESTROY_INFRA', defaultValue: false, description: 'Check this to destroy infrastructure')
    }

    post {
        success {
            echo "✅ Application deployed successfully on EC2!"
        }
        failure {
            echo " Deployment failed. Check logs."
        }
    }
}

pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        ECR_REPO = '312596057535.dkr.ecr.us-east-1.amazonaws.com/cloth-blog'
        IMAGE_TAG = 'latest'
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/sindhuja719/ClothblogDevops.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                bat "docker build -t %ECR_REPO%:%IMAGE_TAG% ."
            }
        }

        stage('Login to ECR') {
            steps {
                withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
                    bat """
                    aws ecr get-login-password --region %AWS_REGION% | docker login --username AWS --password-stdin %ECR_REPO%
                    """
                }
            }
        }

        stage('Push Docker Image to ECR') {
            steps {
                bat """
                docker push %ECR_REPO%:%IMAGE_TAG%
                """
            }
        }

        stage('Deploy with Terraform') {
            steps {
                dir('terraform') {
                    withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
                        bat """
                        terraform init -input=false
                        terraform apply -auto-approve
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ Cloth Blog deployed successfully to AWS EC2!"
        }
        failure {
            echo "❌ Deployment failed. Check logs."
        }
    }
}

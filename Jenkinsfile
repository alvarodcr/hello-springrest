//JENKINSFILE								//GITHUB --> DOCKER --> TERRAFORM --> ANSIBLE --> AWS

def GIT_REPO_PKG = 'ghcr.io/alvarodcr/hello-terraform/helloterraformpkg'// GHCR_PKG package repository
//def GIT_REPO_SSH = 'git@github.com:alvarodcr/hello-terraform.git'	// GIT SSH repository
def GIT_SSH = 'git-ssh'							// GIT SSH credentials
def GIT_USER = 'alvarodcr'						// GIT username
def GHCR_TOKEN = 'ghrc_token'						// ghcr.io credential (token)
def AWS_KEY_SSH = 'ssh-amazon'						// AWS credentials for connecting via SSH
def AWS_KEY_ROOT = '2934977b-3b53-4065-8b4a-312c2259a9f3'		// AWS credentials for creating instances
def ANSIBLE_INV = 'ansible/aws_ec2.yml' 				// Ansible inventory path
def ANSIBLE_PB = 'ansible/hello_2048.yml' 				// Ansible playbook path
def VERSION = "2.0.${BUILD_NUMBER}"					// TAG version with BUILD_NUMBER

pipeline {
	
    agent any 
    options {
        timestamps()
        ansiColor('xterm')
    }
	
    stages {
        
	stage('DOCKER --> BUILDING & TAGGING IMAGE') {
            steps{
		sh """
		docker-compose build
                git tag ${VERSION}
                docker tag ${GIT_REPO_PKG}:latest ${GIT_REPO_PKG}:${VERSION}
		"""
		sshagent([GIT_SSH]) {
		    sh 'git push --tags'
		}
	    }	                              
        }  
        
        stage('DOCKER --> LOGIN & PUSHING TO GHCR.IO') {
            steps{ 
		withCredentials([string(credentialsId: GHCR_TOKEN, variable: 'TOKEN_GIT')]) {
		    sh """
		    echo $TOKEN_GIT | docker login ghcr.io -u ${GIT_USER} --password-stdin
		    docker push ${GIT_REPO_PKG}:${VERSION}
		    """	
		}
            }
        }   
        
        stage('TERRAFORM --> INIT & FMT & VALIDATE') {
            steps {
                sh 'terraform init && terraform fmt && terraform validate'
            }
        }
         
        stage('TERRAFORM --> BUILDING AWS EC2 INSTANCE') {
            steps {
		withAWS(credentials:AWS_KEY_ROOT) {
                    sh 'terraform apply -auto-approve -lock=false'                         
                }
            }
        }
	    
	stage('ANSIBLE --> SETTING AWS EC2 INSTANCE') {
            steps {
		withAWS(credentials:AWS_KEY_ROOT) {
		    ansiblePlaybook colorized: true, credentialsId:AWS_KEY_SSH, inventory:ANSIBLE_INV, playbook:ANSIBLE_PB                            
		}
            }
        }
    
    }     
}

//JENKINSFILE								//GITHUB --> DOCKER --> TERRAFORM --> ANSIBLE --> AWS

def GIT_REPO_PKG = 'ghcr.io/alvarodcr/hello-springrest/springrest'// GHCR_PKG package repository
def GIT_SSH = 'git-ssh'							// GIT SSH credentials
def GIT_USER = 'alvarodcr'						// GIT username
def GHCR_TOKEN = 'ghrc_token'						// ghcr.io credential (token)
def AWS_KEY_SSH = 'ssh-amazon'						// AWS credentials for connecting via SSH
def AWS_KEY_ROOT = '2934977b-3b53-4065-8b4a-312c2259a9f3'		// AWS credentials for creating instances
def VERSION = "1.0.${BUILD_NUMBER}"					// TAG version with BUILD_NUMBER

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
		    docker push ${GIT_REPO_PKG}:latest
		    """	
		}
            }
        }   
        
        stage('EB --> DEPLOYING') {
            steps {
		dir ("eb-files"){
		    sh 'eb deploy'
		}
	    }
        }
    }    
       	
        post {
    	    always {
		junit '**/target/surefire-reports/TEST-*.xml'
    		}
    	     failure {
		echo "\033[20mFAILED!\033[0m"
    		}
	}	   
         
}

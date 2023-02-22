//JENKINSFILE								//GITHUB --> DOCKER --> TERRAFORM --> ANSIBLE --> AWS

def GIT_REPO_PKG = 'ghcr.io/alvarodcr/hello-springrest/springrest'// GHCR_PKG package repository
def GIT_SSH = 'git-ssh'							// GIT SSH credentials
def GIT_USER = 'alvarodcr'						// GIT username
def GHCR_TOKEN = 'ghrc_token'						// ghcr.io credential (token)
def AWS_KEY_SSH = 'ssh-amazon'						// AWS credentials for connecting via SSH
def AWS_KEY_ROOT = '2934977b-3b53-4065-8b4a-312c2259a9f3'		// AWS credentials for creating instances
def VERSION = "1.0.${BUILD_NUMBER}"					// TAG version with BUILD_NUMBER

pipeline {
    // Define the Jenkins agent to run the pipeline on
    agent any 
    
    // Define some options for the pipeline, such as timestamps and ANSI color support
    options {
        timestamps()
        ansiColor('xterm')
    }
	
    // Define the stages of the pipeline
    stages {
        // Define the "GRADLE --> TESTING" stage
        stage('GRADLE --> TESTING') {
            // Define the steps to run in this stage, which include running the "test" task with Gradle
            steps{
                sh './gradlew test'   
            }        
            // Define post-actions to run after the stage has completed, including printing test results and error messages
            post {
                success {
                    // Publish test results in JUnit format and print test result files in the console
                    junit 'build/test-results/**/*.xml'
                    step([$class: 'TestResultAnalyzer', testResults: 'build/test-results/**/*.xml'])
                }
                failure {
                    // Print an error message in red if the stage fails
                    echo "\033[20mFAILED!\033[0m"
                }
            }	 
        }
        
        // Define the "DOCKER --> BUILDING & TAGGING IMAGE" stage
        stage('DOCKER --> BUILDING & TAGGING IMAGE') {
            // Define the steps to run in this stage, which include building a Docker image and tagging it with a version number
            steps{
                sh """
                docker-compose build
                git tag ${VERSION}
                docker tag ${GIT_REPO_PKG}:latest ${GIT_REPO_PKG}:${VERSION}
                """
                // Use SSH authentication to push the Git tags to the remote repository
                sshagent([GIT_SSH]) {
                    sh 'git push --tags'
                }
            }	                              
        }  
        
        // Define the "DOCKER --> LOGIN & PUSHING TO GHCR.IO" stage
        stage('DOCKER --> LOGIN & PUSHING TO GHCR.IO') {
            steps{ 
                // Authenticate to the GitHub Container Registry (GHCR) using a Docker access token, and push the Docker images to GHCR
                withCredentials([string(credentialsId: GHCR_TOKEN, variable: 'TOKEN_GIT')]) {
                    sh """
                    echo $TOKEN_GIT | docker login ghcr.io -u ${GIT_USER} --password-stdin
                    docker push ${GIT_REPO_PKG}:${VERSION}
                    docker push ${GIT_REPO_PKG}:latest
                    """	
                }
            }
        }   
        
        // Define the "EB --> DEPLOYING" stage
        stage('EB --> DEPLOYING') {
            steps {
                withAWS(credentials:AWS_KEY_ROOT) {
		    // Change to the "eb-files" directory and deploy the Elastic Beanstalk application
		    dir ("eb-files"){
                        sh 'eb deploy'
		    }
		}
            }
        }
    
    }                
}

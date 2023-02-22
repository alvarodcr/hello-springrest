//JENKINSFILE								//GITHUB --> DOCKER --> ELASTIC	BEANSTALK --> AWS

def GIT_REPO_PKG = 'ghcr.io/alvarodcr/hello-springrest/springrest'	// GIT package repository
def GIT_SSH = 'git-ssh'							// GIT SSH credentials
def GIT_USER = 'alvarodcr'						// GIT username
def GHCR_TOKEN = 'ghrc_token'						// ghcr.io credential (token)
def AWS_KEY_SSH = 'ssh-amazon'						// AWS credentials for connecting via SSH
def AWS_KEY_ROOT = '2934977b-3b53-4065-8b4a-312c2259a9f3'		// AWS credentials for creating instances
def VERSION = "1.0.${BUILD_NUMBER}"					// TAG version with BUILD_NUMBER

pipeline {
    agent any 
    
    // Define some options for the pipeline, such as timestamps and ANSI color support
    options {
        timestamps()
        ansiColor('xterm')
    }
	
    // Define the stages of the pipeline
    stages {
     
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

		    // Run Jacoco code coverage report and publish results
		    jacoco(
		        execPattern: 'build/jacoco/test.exec',			// Path to the JaCoCo .exec file generated by the test task
		        classPattern: 'build/classes/java/main/**/*.class',	// Pattern for class files to analyze
		        sourcePattern: 'src/main/java/**/*.java'		// Pattern for Java source files to analyze
		    )

		    // Publish the Jacoco HTML coverage report using the Publish HTML plugin
		    publishHTML([
		        target: [
			    allowMissing: false,        			// Fail the build if the report file is missing
			    alwaysLinkToLastBuild: true,			// Link to the latest build even if no report is found
			    keepAll: true,             				// Keep HTML reports for all builds
			    reportDir: 'build/jacoco',      			// Define the directory path of the report
			    reportFiles: 'index.html',   	 		// Define the name of the HTML report file
			    reportName: "HTML Report" 				// Define the name of the report
			    reportTitles: 'JACOCO HTML Report'			// Define the title of the creport
		        ]
		    ])
		}
		failure {
		    // Print an error message in red if the stage fails
		    echo "\033[20mFAILED!\033[0m"
		}
	    }	 
	}
        
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
        
        stage('ELASTIC BEANSTALK --> DEPLOYING') {
            steps {
		// This step allows the pipeline to use the specified AWS credentials when performing AWS related tasks.
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

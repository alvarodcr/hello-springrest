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
    
    options {
        timestamps() // Add timestamps to the console output
        ansiColor('xterm') // Enable ANSI color support for the console
    }
	
    stages {
     
	stage('GRADLE-JACOCO --> TESTING') {
	    steps {
                sh './gradlew test jacocoTestReport' // Run the "test" and "jacocoTestReport" tasks with Gradle
            }
            post {
                success {
		    archiveArtifacts 'build/libs/*.jar' // Archive the generated JAR files
                    jacoco(
			execPattern: 'build/jacoco/*.exec', // Specify the pattern for the exec files
			classPattern: '**/classes', // Specify the pattern for the Java class files
			sourcePattern: '**/src/main/java', // Specify the pattern for the source code files
		    )
                }
		failure {
		    echo "\033[20mFAILED!\033[0m" // Print an error message in red if the stage fails
		}
	    }	 
	}
	
	stage('AQUA-TRIVY --> SECURITY SCAN') {
	    // Run AquaTrivy with the current working directory as the scan target and generate a JSON report in the workspace directory
	    steps {
		    sh 'trivy fs -f json -o build/reports/trivy/trivy-report.json --security-checks vuln,secret,config .'
	    }
	    post {
		success {
		    // Call the recordIssues task and specify the AquaTrivy tool to collect JSON reports generated in the path /workspace
		    recordIssues(tools: [
			trivy(pattern: 'build/reports/trivy/*.json')
		    ])
		}
		failure {
		    echo "\033[20mFAILED!\033[0m" // Print an error message in red if the stage fails
		}
	    }
	}
	    
	stage('GRADLE-PMD --> TESTING') {
            steps {
                sh './gradlew check' // Run the "check" task with Gradle tro generate pmd report files
            }
            post {
                success {
		    // Call the recordIssues task and specify the PMD plugin to collect XML reports generated in the path build/reports/pmd
		    recordIssues(tools: [
			pmdParser(pattern: 'build/reports/pmd/*.xml')
		    ])
		    // Publish the HTML reports in the build/reports/pmd directory so they can be viewed in Jenkins
		    publishHTML(target: [
                        allowMissing: false, // Do not allow missing reports
                        alwaysLinkToLastBuild: true, // Always link to the latest generated report
                        keepAll: true, // Keep all generated reports, not just the latest one
                        reportDir: 'build/reports/pmd', // Directory where the reports are located
                        reportFiles: '*.html', // HTML files pattern to include in the report
                        reportName: 'PMD Report' // Name of the report to display in Jenkins
                    ])
                }
		failure {
		    echo "\033[20mFAILED!\033[0m" // Print an error message in red if the stage fails
		}
	    }	      
        }
	    
        stage('DOCKER --> BUILDING & TAGGING IMAGE') {
            // Define building a Docker image and tagging it with a version number
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
             // Authenticate to the GitHub Container Registry (GHCR) using a Docker access token, and push the Docker images to GHCR
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

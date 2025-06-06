pipeline {
    agent any

    environment {
        NVD_API_KEY = credentials('nvd_api_key')
    }

    stages {
        stage('Clone Repo') {
            steps {
                git branch: 'main', url: 'https://github.com/Ashish1806xx/JenkinsLab.git'
            }
        }

        stage('Build') {
            steps {
                echo 'Running Python App'
                sh 'python3 app.py'
            }
        }

        stage('Test') {
            steps {
                echo 'Simulated Test Passed'
            }
        }

        stage('Security Scan - DependencyCheck') {
            steps {
                sh '/opt/dependency-check/bin/dependency-check.sh --nvdApiKey ${NVD_API_KEY} --project "JenkinsLab" --scan . --format HTML --out dependency-check-report'
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'dependency-check-report/*.html', fingerprint: true
        }
    }
}

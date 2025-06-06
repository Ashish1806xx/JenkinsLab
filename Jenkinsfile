pipeline {
    agent any

    stages {
        stage('Clone Repo') {
            steps {
                git 'https://github.com/Ashish1806xx/Jenkinslab.git'
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
    }
}

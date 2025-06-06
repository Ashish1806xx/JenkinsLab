pipeline {
    agent any

    stages {
        stage('Clone Repo') {
            steps {
                git 'https://github.com/Ashish1806xx/ci-cd-sample-app.git'
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

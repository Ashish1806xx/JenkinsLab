pipeline {
    agent any

    stages {
        stage('Clone') {
            steps {
                git 'https://github.com/Ashish1806xx/JenkinsLab.git'
            }
        }

        stage('Build') {
            steps {
                echo 'Simulating build step...'
                sh 'echo Build completed'
            }
        }

        stage('Test') {
            steps {
                echo 'Running dummy test...'
                sh 'echo All tests passed'
            }
        }
    }
}

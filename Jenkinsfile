pipeline {
  agent any

  environment {
    // Image tag used locally for scans and deploys.
    // It's fine even if you don't push to GHCR.
    IMAGE = "ghcr.io/ashish/jenkinslab:${env.BUILD_NUMBER}"
    DOCKER_HOST = "unix:///var/run/docker.sock"
  }

  options {
    timestamps()
    ansiColor('xterm')
    buildDiscarder(logRotator(numToKeepStr: '15'))
  }

  // If you don't use GitHub webhooks, this polls every 5 minutes
  triggers { pollSCM('H/5 * * * *') }

  stages {

    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Build') {
      steps {
        sh '''
          # Build the app image (expects app/Dockerfile)
          docker build -t "$IMAGE" ./app
        '''
      }
    }

    stage('Unit Tests') {
      steps {
        sh '''
          # Run tests inside the built image, mounting source
          docker run --rm -v "$PWD/app:/app" -w /app "$IMAGE" sh -c '
            python -m pytest -q
          '
        '''
      }
    }

    stage('SAST (Semgrep)') {
      steps {
        sh '''
          docker run --rm -v "$PWD:/src" semgrep/semgrep:latest \
            semgrep --config p/ci --error --timeout 300 --metrics=off -q
        '''
      }
    }

    stage('Dependency/Image Scan (Trivy)') {
      steps {
        sh '''
          docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
            aquasec/trivy:latest image --exit-code 1 --severity CRITICAL,HIGH "$IMAGE"
        '''
      }
    }

    stage('IaC Scan (tfsec)') {
      steps {
        dir('iac/terraform') {
          sh '''
            docker run --rm -v "$PWD:/workdir" -w /workdir aquasecurity/tfsec:latest
          '''
        }
      }
    }

    stage('DAST (OWASP ZAP Baseline)') {
      steps {
        sh '''
          # Start the app for scanning
          docker run -d --rm --name app-under-test -p 8080:8080 "$IMAGE"
          # Give it a moment
          sleep 5

          # Run ZAP baseline (non-auth)
          docker run --rm --network host owasp/zap2docker-stable zap-baseline.py \
            -t http://localhost:8080 -m 3 -r zap_report.html -x zap_report.xml || true

          # Stop app
          docker stop app-under-test || true

          # Fail the build on Medium/High risks
          if grep -E "<riskcode>(2|3)</riskcode>" zap_report.xml >/dev/null; then
            echo "ZAP found Medium/High risks"; exit 1; fi
        '''
      }
      post {
        always {
          archiveArtifacts artifacts: 'zap_report.*', fingerprint: true
        }
      }
    }

    stage('Terraform Plan') {
      steps {
        dir('iac/terraform') {
          sh '''
            docker run --rm -v "$PWD:/tf" -w /tf hashicorp/terraform:1.6 init -input=false
            docker run --rm -v "$PWD:/tf" -w /tf hashicorp/terraform:1.6 validate
            docker run --rm -v "$PWD:/tf" -w /tf hashicorp/terraform:1.6 plan \
              -out=tfplan -var image="$IMAGE"
          '''
        }
      }
      post {
        success {
          archiveArtifacts artifacts: 'iac/terraform/tfplan', fingerprint: true
        }
      }
    }

    stage('Apply & Deploy') {
      when { branch 'main' }
      steps {
        dir('iac/terraform') {
          sh '''
            docker run --rm -v "$PWD:/tf" -w /tf \
              -v /var/run/docker.sock:/var/run/docker.sock \
              hashicorp/terraform:1.6 apply -auto-approve tfplan
          '''
        }
      }
    }
  }

  post {
    always {
      script { currentBuild.description = "Image: ${env.IMAGE}" }
    }
    success {
      script {
        try {
          emailext subject: "✅ ${env.JOB_NAME} #${env.BUILD_NUMBER} passed",
                   to: "ashishdaida01@gmail.com",
                   body: "All stages succeeded.\\nImage: ${env.IMAGE}\\nBuild: ${env.BUILD_URL}"
        } catch (err) {
          echo "Email not configured (success notice skipped)."
        }
      }
    }
    failure {
      script {
        try {
          emailext subject: "❌ ${env.JOB_NAME} #${env.BUILD_NUMBER} failed",
                   to: "ashishdaida01@gmail.com",
                   body: "Job: ${env.JOB_NAME}\\nBuild: ${env.BUILD_URL}\\nImage: ${env.IMAGE}"
        } catch (err) {
          echo "Email not configured (failure notice skipped)."
        }
      }
    }
  }
}

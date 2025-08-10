pipeline {
  agent any

  environment {
    IMAGE = "ghcr.io/ashish/jenkinslab:${env.BUILD_NUMBER}"
    DOCKER_HOST = "unix:///var/run/docker.sock"
  }

  options {
    timestamps()
    buildDiscarder(logRotator(numToKeepStr: '15'))
  }

  triggers { pollSCM('H/5 * * * *') } // if no webhook

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Build') {
      steps {
        sh '''
          rm -rf app/.pytest_cache app/__pycache__ || true
          find app -type d -name "__pycache__" -exec rm -rf {} + || true
          docker build -t "$IMAGE" ./app
        '''
      }
    }

    stage('Unit Tests') {
      steps {
        sh '''
          docker run --rm -v "$PWD:/work" -w /work "$IMAGE" sh -c '
            python -m pytest -q tests || python -m pytest -q app/tests
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
            aquasec/trivy:latest image --exit-code 1 \
            --severity CRITICAL --ignore-unfixed --scanners vuln "$IMAGE"
        '''
      }
    }

    stage('IaC Scan (tfsec)') {
      steps {
        dir('iac/terraform') {
          sh 'docker run --rm -v "$PWD:/workdir" -w /workdir aquasec/tfsec:latest'
        }
      }
    }

    stage('DAST (OWASP ZAP Baseline)') {
      steps {
        sh '''
          # Run app on host port 8081 (Jenkins uses 8080)
          docker run -d --rm --name app-under-test -p 8081:8080 "$IMAGE"
          sleep 12

          # Use the maintained ZAP image; write reports into the workspace
          docker run --rm --network host \
            -v "$PWD:/zap/wrk" -w /zap/wrk \
            ghcr.io/zaproxy/zaproxy:stable zap-baseline.py \
              -t http://localhost:8081 -m 3 -r zap_report.html -x zap_report.xml || true

          docker stop app-under-test || true

          # Fail the build on Medium/High findings if report exists
          if [ -f zap_report.xml ] && grep -E "<riskcode>(2|3)</riskcode>" zap_report.xml >/dev/null; then
            echo "ZAP found Medium/High risks"; exit 1; fi
        '''
      }
      post {
        always {
          archiveArtifacts artifacts: 'zap_report.*', fingerprint: true, allowEmptyArchive: true
        }
      }
    }

    stage('Terraform Plan') {
      steps {
        dir('iac/terraform') {
          sh '''
            docker run --rm -v "$PWD:/tf" -w /tf hashicorp/terraform:1.6 init -input=false
            docker run --rm -v "$PWD:/tf" -w /tf hashicorp/terraform:1.6 validate
            docker run --rm -v "$PWD:/tf" -w /tf \
              -v /var/run/docker.sock:/var/run/docker.sock \
              hashicorp/terraform:1.6 plan -out=tfplan -var image="$IMAGE"
          '''
        }
      }
      post {
        success { archiveArtifacts artifacts: 'iac/terraform/tfplan', fingerprint: true }
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
    always { script { currentBuild.description = "Image: ${env.IMAGE}" } }
    success { echo "Build passed ✅" }
    failure { echo "Build failed. Check stage logs." }
  }
}

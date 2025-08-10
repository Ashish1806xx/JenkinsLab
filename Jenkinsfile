pipeline {
  agent any
  options {
    timestamps()
    ansiColor('xterm')
  }
  environment {
    IMAGE        = "ghcr.io/ashish/jenkinslab:${BUILD_NUMBER}"
    APP_PORT     = "8080"        // container port
    HOST_PORT    = "8081"        // local port for DAST
    TF_HOST_PORT = "8082"        // port used by Terraform plan/container
  }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build') {
      steps {
        sh '''
          set -euxo pipefail
          rm -rf app/.pytest_cache || true
          find app -type d -name __pycache__ -exec rm -rf {} + || true
          docker build -t "${IMAGE}" ./app
        '''
      }
    }

    stage('Unit Tests') {
      steps {
        sh '''
          set -euxo pipefail
          docker run --rm \
            -v "$PWD:/work" -w /work \
            "${IMAGE}" \
            sh -c 'python -m pytest -q tests || python -m pytest -q app/tests'
        '''
      }
    }

    stage('SAST (Semgrep)') {
      steps {
        sh '''
          set -euxo pipefail
          docker run --rm -v "$PWD:/src" semgrep/semgrep:latest \
            semgrep --config p/ci --error --timeout 300 --metrics=off -q
        '''
      }
    }

    stage('Dependency/Image Scan (Trivy)') {
      steps {
        sh '''
          set -euxo pipefail
          docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
            aquasec/trivy:latest \
            image --exit-code 1 --severity CRITICAL --ignore-unfixed --scanners vuln "${IMAGE}"
        '''
      }
    }

    stage('IaC Scan (tfsec)') {
      steps {
        dir('iac/terraform') {
          sh '''
            set -euxo pipefail
            docker run --rm \
              -v "$PWD:/workdir" -w /workdir \
              aquasec/tfsec:latest
          '''
        }
      }
    }

    stage('DAST (OWASP ZAP Baseline)') {
      steps {
        sh '''
          set -euxo pipefail

          # Start app to scan
          docker run -d --rm --name app-under-test -p "${HOST_PORT}:${APP_PORT}" "${IMAGE}"
          sleep 12

          # Run ZAP Baseline and write reports as root to avoid permission issues
          rm -rf zap_reports && mkdir -p zap_reports
          docker run --rm --network host -u 0:0 \
            -v "$PWD/zap_reports:/zap/wrk" -w /zap/wrk \
            ghcr.io/zaproxy/zaproxy:stable \
            zap-baseline.py -t "http://localhost:${HOST_PORT}" -m 10 -r zap_report.html -x zap_report.xml || true

          docker stop app-under-test || true

          # Fail ONLY if HIGH risks exist
          if grep -q '<riskcode>3</riskcode>' zap_reports/zap_report.xml; then
            echo "ZAP found HIGH risk alerts"; exit 1
          fi
        '''
      }
      post {
        always {
          archiveArtifacts artifacts: 'zap_reports/zap_report.*', onlyIfSuccessful: false
          fingerprint 'zap_reports/zap_report.*'
        }
      }
    }

    stage('Terraform Plan') {
      steps {
        dir('iac/terraform') {
          sh '''
            set -euxo pipefail
            # Allow Terraform docker provider to access host Docker
            docker run --rm \
              -v "$PWD:/tf" \
              -v /var/run/docker.sock:/var/run/docker.sock \
              -w /tf hashicorp/terraform:1.6 \
              init -input=false

            docker run --rm \
              -v "$PWD:/tf" \
              -v /var/run/docker.sock:/var/run/docker.sock \
              -w /tf hashicorp/terraform:1.6 \
              plan -input=false -no-color -out=tfplan \
                -var="image=${IMAGE}" \
                -var="container_name=jenkinslab-app" \
                -var="host_port=${TF_HOST_PORT}" \
                -var="container_port=${APP_PORT}"
          '''
        }
      }
    }

    stage('Apply & Deploy') {
      when { expression { false } } // disabled by default; enable when ready
      steps {
        echo 'Apply is disabled for now.'
      }
    }
  }

  post {
    failure {
      echo 'Build failed. Check stage logs.'
    }
  }
}

pipeline {
    agent any

    parameters {
        string(name: 'RASPI_HOST', defaultValue: '192.168.1.2', description: 'Raspberry Pi IP address')
        string(name: 'RASPI_USER', defaultValue: 'pi', description: 'SSH username for Raspberry Pi')
        string(name: 'MAX_DISK_USE_PERCENT', defaultValue: '90', description: 'Fail if root filesystem usage is >= this value')
        booleanParam(name: 'RUN_PING_PRECHECK', defaultValue: true, description: 'Run ping before SSH validation')
    }

    environment {
        VENV_DIR = '.venv'
        REPORT_DIR = 'reports'
    }

    stages {
        stage('Checkout GitHub Repo') {
            steps {
                checkout scm
            }
        }

        stage('Prepare Python + Robot Environment') {
            steps {
                sh '''
                    set -eux
                    python3 --version
                    python3 -m venv ${VENV_DIR}
                    . ${VENV_DIR}/bin/activate
                    python -m pip install --upgrade pip
                    pip install -r requirements.txt
                    mkdir -p ${REPORT_DIR}
                '''
            }
        }

        stage('Network Precheck') {
            when {
                expression { return params.RUN_PING_PRECHECK }
            }
            steps {
                sh '''
                    set -eux
                    ping -c 3 ${RASPI_HOST}
                '''
            }
        }

        stage('Run Raspberry Pi Robot Testcases') {
            steps {
                withCredentials([
                    sshUserPrivateKey(
                        credentialsId: 'raspi-ssh-key',
                        keyFileVariable: 'SSH_KEY_FILE',
                        usernameVariable: 'SSH_USER_FROM_CRED'
                    )
                ]) {
                    sh '''
                        set -eux
                        . ${VENV_DIR}/bin/activate

                        robot \
                          --outputdir ${REPORT_DIR} \
                          --xunit xunit.xml \
                          --loglevel INFO \
                          --variable RASPI_HOST:${RASPI_HOST} \
                          --variable RASPI_USER:${RASPI_USER} \
                          --variable SSH_KEY_FILE:${SSH_KEY_FILE} \
                          --variable MAX_DISK_USE_PERCENT:${MAX_DISK_USE_PERCENT} \
                          tests/raspi_basic_validation.robot
                    '''
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'reports/**', allowEmptyArchive: true
            junit allowEmptyResults: true, testResults: 'reports/xunit.xml'
        }
        success {
            echo 'Raspberry Pi validation PASSED.'
        }
        failure {
            echo 'Raspberry Pi validation FAILED. Check reports/log.html and reports/report.html.'
        }
    }
}

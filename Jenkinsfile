pipeline {
    agent any

    parameters {
        string(name: 'RASPI_HOST', defaultValue: '192.168.1.2', description: 'Raspberry Pi IP address')
        string(name: 'RASPI_USER', defaultValue: 'pi', description: 'Raspberry Pi SSH username')
        string(name: 'MAX_DISK_USE_PERCENT', defaultValue: '90', description: 'Maximum allowed root disk usage percent')
        booleanParam(name: 'RUN_PING_PRECHECK', defaultValue: true, description: 'Ping Raspberry Pi before running Robot test')
    }

    environment {
        VENV_DIR = '.venv'
        REPORT_DIR = 'reports'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Show Environment') {
            steps {
                bat '''
                echo Current directory:
                cd

                echo Python version:
                python --version

                echo Git version:
                git --version
                '''
            }
        }

        stage('Prepare Python Environment') {
            steps {
                bat '''
                if exist %VENV_DIR% rmdir /s /q %VENV_DIR%

                python -m venv %VENV_DIR%

                %VENV_DIR%\\Scripts\\python.exe -m pip install --upgrade pip
                %VENV_DIR%\\Scripts\\pip.exe install -r requirements.txt

                if exist %REPORT_DIR% rmdir /s /q %REPORT_DIR%
                mkdir %REPORT_DIR%
                '''
            }
        }

        stage('Ping Raspberry Pi') {
            when {
                expression { return params.RUN_PING_PRECHECK }
            }
            steps {
                bat '''
                ping -n 2 %RASPI_HOST%
                '''
            }
        }

        stage('Run Raspberry Pi Robot Tests') {
            steps {
                withCredentials([
                    sshUserPrivateKey(
                        credentialsId: 'raspi-ssh-key',
                        keyFileVariable: 'SSH_KEY_FILE',
                        usernameVariable: 'SSH_USER_FROM_CRED'
                    )
                ]) {
                    bat '''
                    %VENV_DIR%\\Scripts\\python.exe -m robot ^
                      --outputdir %REPORT_DIR% ^
                      --xunit xunit.xml ^
                      --loglevel INFO ^
                      --variable RASPI_HOST:%RASPI_HOST% ^
                      --variable RASPI_USER:%RASPI_USER% ^
                      --variable SSH_KEY_FILE:"%SSH_KEY_FILE%" ^
                      --variable MAX_DISK_USE_PERCENT:%MAX_DISK_USE_PERCENT% ^
                      tests\\raspi_basic_validation.robot
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
            echo 'Raspberry Pi validation FAILED. Check Console Output and reports/log.html.'
        }
    }
}
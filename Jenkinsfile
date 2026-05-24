pipeline {
    agent any

    parameters {
        string(name: 'RASPI_HOST', defaultValue: '192.168.1.2', description: 'Raspberry Pi IP address')
        string(name: 'RASPI_USER', defaultValue: '', description: 'Optional Raspberry Pi SSH username override. Leave blank to use the Jenkins credential username.')
        string(name: 'MAX_DISK_USE_PERCENT', defaultValue: '90', description: 'Maximum allowed root disk usage percent')
        booleanParam(name: 'RUN_PING_PRECHECK', defaultValue: true, description: 'Ping Raspberry Pi before running Robot test')
    }

    environment {
        VENV_DIR = 'venv'
        REPORT_DIR = 'reports'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Debug Workspace') {
            steps {
                bat '''
                echo Current workspace:
                cd

                echo Listing files:
                dir

                echo Checking tests folder:
                dir tests

                echo Checking Python:
                python --version
                where python

                echo Checking Git:
                git --version
                '''
            }
        }

        stage('Prepare Python Environment') {
            steps {
                bat '''
                if exist venv rmdir /s /q venv
                if exist reports rmdir /s /q reports

                python -m venv venv

                venv\\Scripts\\python.exe --version
                venv\\Scripts\\python.exe -m pip install --upgrade pip
                venv\\Scripts\\python.exe -m pip install -r requirements.txt

                mkdir reports
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
                        passphraseVariable: 'SSH_KEY_PASSPHRASE',
                        usernameVariable: 'SSH_USER_FROM_CRED'
                    )
                ]) {
                    bat '''
                    echo Running Robot Framework test
                    echo Raspberry Pi Host: %RASPI_HOST%

                    set "EFFECTIVE_RASPI_USER=%RASPI_USER%"
                    if "%EFFECTIVE_RASPI_USER%"=="" set "EFFECTIVE_RASPI_USER=%SSH_USER_FROM_CRED%"
                    echo Raspberry Pi User: %EFFECTIVE_RASPI_USER%

                    venv\\Scripts\\python.exe -m robot --outputdir reports --xunit xunit.xml --loglevel INFO --variable RASPI_HOST:%RASPI_HOST% --variable RASPI_USER:%EFFECTIVE_RASPI_USER% --variable SSH_KEY_FILE:"%SSH_KEY_FILE%" --variable SSH_KEY_PASSPHRASE:"%SSH_KEY_PASSPHRASE%" --variable MAX_DISK_USE_PERCENT:%MAX_DISK_USE_PERCENT% tests\\raspi_basic_validation.robot
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

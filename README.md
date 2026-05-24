# Raspberry Pi Jenkins GitHub Test Flow

This project demonstrates a complete CI test flow:

VS Code -> GitHub -> Jenkins -> SSH to Raspberry Pi -> Robot Framework validation -> HTML/JUnit reports

Default Raspberry Pi target:

```text
192.168.1.8
```

## Testcases

The Robot suite validates:

1. SSH login and hostname
2. OS information
3. Kernel and architecture
4. SSH service status
5. Disk usage threshold
6. Available memory
7. CPU load command
8. Python3 availability
9. CPU temperature if supported

## Repository structure

```text
raspi-jenkins-github-demo/
├── Jenkinsfile
├── README.md
├── requirements.txt
├── tests/
│   └── raspi_basic_validation.robot
└── .vscode/
    ├── extensions.json
    └── settings.json
```

## Local execution from VS Code terminal

Create a virtual environment:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

Run the Robot test locally:

```bash
robot \
  --outputdir reports \
  --variable RASPI_HOST:192.168.1.8 \
  --variable RASPI_USER:pi \
  --variable SSH_KEY_FILE:$HOME/.ssh/jenkins_raspi \
  tests/raspi_basic_validation.robot
```

Open the report:

```bash
firefox reports/report.html
```

## Jenkins credential requirement

Create a Jenkins credential:

```text
Kind: SSH Username with private key
ID: raspi-ssh-key
Username: pi or your Raspberry Pi username
Private key: Jenkins-to-Raspberry private key
```

## Jenkins job type

Create a Pipeline job and choose:

```text
Pipeline script from SCM
SCM: Git
Repository URL: your GitHub repo URL
Branch: main
Script Path: Jenkinsfile
```

## Expected Jenkins output

If validation passes, Jenkins archives:

```text
reports/report.html
reports/log.html
reports/output.xml
reports/xunit.xml
```


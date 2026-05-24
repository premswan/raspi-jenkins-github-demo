*** Settings ***
Documentation     Basic CI validation for Raspberry Pi through Jenkins + GitHub + Robot Framework.
...               Jenkins connects to Raspberry Pi by SSH and validates OS, service, disk, memory, CPU load, and Python.
Library           SSHLibrary
Suite Setup       Open Raspberry SSH Session
Suite Teardown    Close All Connections

*** Variables ***
${RASPI_HOST}                 192.168.1.2
${RASPI_USER}                 pi
${SSH_KEY_FILE}               %{SSH_KEY_FILE=}
${SSH_KEY_PASSPHRASE}         %{SSH_KEY_PASSPHRASE=}
${SSH_TIMEOUT}                10 seconds
${MAX_DISK_USE_PERCENT}       90
${MIN_MEM_AVAILABLE_MB}       100

*** Keywords ***
Open Raspberry SSH Session
    [Documentation]    Opens SSH connection to Raspberry Pi using Jenkins SSH private-key credential.
    Should Not Be Empty    ${RASPI_HOST}
    Should Not Be Empty    ${RASPI_USER}
    Should Not Be Empty    ${SSH_KEY_FILE}
    Open Connection    ${RASPI_HOST}    timeout=${SSH_TIMEOUT}
    Login With Public Key    ${RASPI_USER}    ${SSH_KEY_FILE}    ${SSH_KEY_PASSPHRASE}

Run Remote Command
    [Arguments]    ${command}
    ${output}=    Execute Command    ${command}
    Log    ${output}
    Log To Console    ${output}
    RETURN    ${output}

*** Test Cases ***
TC01 Verify Raspberry SSH Login And Hostname
    [Documentation]    Validates SSH login and confirms hostname command returns output.
    ${hostname}=    Run Remote Command    hostname
    Should Not Be Empty    ${hostname}

TC02 Validate Operating System Information
    [Documentation]    Checks that the remote Linux OS details are readable.
    ${os}=    Run Remote Command    cat /etc/os-release | head -1
    Should Contain Any    ${os}    PRETTY_NAME    Raspberry    Debian    Ubuntu

TC03 Validate Kernel And Architecture
    [Documentation]    Captures kernel and architecture details for build evidence.
    ${kernel}=    Run Remote Command    uname -a
    Should Not Be Empty    ${kernel}

TC04 Validate SSH Service Is Active
    [Documentation]    Ensures SSH daemon is active on Raspberry Pi.
    ${status}=    Run Remote Command    systemctl is-active ssh || systemctl is-active sshd
    Should Contain    ${status}    active

TC05 Validate Root Filesystem Disk Usage
    [Documentation]    Fails if / filesystem usage is greater than or equal to threshold.
    ${disk}=    Run Remote Command    df -P / | awk 'NR==2 {print $5}' | tr -d '%'
    ${disk_int}=    Convert To Integer    ${disk}
    Should Be True    ${disk_int} < ${MAX_DISK_USE_PERCENT}    msg=Disk usage is ${disk_int}%, threshold is ${MAX_DISK_USE_PERCENT}%

TC06 Validate Available Memory
    [Documentation]    Fails if available memory is less than minimum expected MB.
    ${mem}=    Run Remote Command    free -m | awk '/Mem:/ {print $7}'
    ${mem_int}=    Convert To Integer    ${mem}
    Should Be True    ${mem_int} >= ${MIN_MEM_AVAILABLE_MB}    msg=Available memory is ${mem_int} MB, expected >= ${MIN_MEM_AVAILABLE_MB} MB

TC07 Validate CPU Load Command
    [Documentation]    Confirms uptime/load-average command works.
    ${uptime}=    Run Remote Command    uptime
    Should Contain    ${uptime}    load average

TC08 Validate Python3 Availability
    [Documentation]    Confirms Python3 is installed on Raspberry Pi.
    ${python}=    Run Remote Command    python3 --version
    Should Contain    ${python}    Python

TC09 Capture CPU Temperature If Supported
    [Documentation]    Captures Raspberry Pi temperature when supported. Does not fail if command is unavailable.
    ${temp}=    Run Remote Command    if command -v vcgencmd >/dev/null 2>&1; then vcgencmd measure_temp; elif [ -f /sys/class/thermal/thermal_zone0/temp ]; then awk '{printf "%.1f C\\n", $1/1000}' /sys/class/thermal/thermal_zone0/temp; else echo temperature_not_supported; fi
    Should Not Be Empty    ${temp}

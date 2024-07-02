# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

resource "aws_ssm_document" "ssm_document_dcv_server_restart" {
  name            = "${var.env.prefix}-nice-dcv-server-restart"
  document_type   = "Automation"
  document_format = "YAML"
  target_type     = "/AWS::EC2::Instance"
  content         = <<DOC
description: |
  ## Restart the DCV Server service
schemaVersion: '0.3'
parameters:
  InstanceId:
    type: AWS::EC2::Instance::Id
    description: (Required) Provide the Instance Id. (e.g. i-07330aca1eb7fecc6 )
    allowedPattern: ^[i]{0,1}-[a-z0-9]{8,17}$
  prefix:
    type: String
    description: (Required) Prefix to be used to retrieve SSM Parameter Store entries
    allowedPattern: ^[a-z_][a-zA-Z0-9_.-]{0,32}$
  project:
    type: String
    description: (Required) project to be used to retrieve SSM Parameter Store entries
    allowedPattern: ^[a-z_][a-zA-Z0-9_.-]{0,32}$
  application:
    type: String
    description: (Required) application to be used to retrieve SSM Parameter Store entries
    allowedPattern: ^[a-z_][a-zA-Z0-9_.-]{0,32}$
  environment:
    type: String
    description: (Required) environment to be used to retrieve SSM Parameter Store entries
    allowedPattern: ^[a-z_][a-zA-Z0-9_.-]{0,32}$
variables:    
  tag:
    type: String
    description: Insatnce tag to be updated when the automation completes
    default: "nice-dcv-server-restart"
mainSteps:
  - name: GetInstance
    action: aws:executeAwsApi
    onFailure: step:exitWithFailure
    nextStep: IsInstanceValid
    inputs:
      Service: ec2
      Api: DescribeInstances
      InstanceIds:
        - '{{InstanceId}}'
      Filters:
        - Name: tag:project
          Values:
            - '{{project}}'
        - Name: tag:application
          Values:
            - '{{application}}'
        - Name: tag:environment
          Values:
            - '{{environment}}'
    outputs:
      - Name: InstanceId
        Selector: $.Reservations[0].Instances[0].InstanceId
        Type: String
      - Name: platform
        Selector: $.Reservations[0].Instances[0].Platform
        Type: String
      - Name: state
        Selector: $.Reservations[0].Instances[0].State.Name
        Type: String
      - Name: username
        Selector: $.Reservations[0].Instances[0].Tags[?(@.Key == 'username')].Value
        Type: String
  - name: IsInstanceValid
    action: aws:branch    
    onFailure: step:exitWithFailure
    inputs:
      Choices:
        - NextStep: exitWithFailure
          Not:
            Variable: '{{GetInstance.state}}'
            StringEquals: running
        - NextStep: exitWithFailure
          Variable: '{{GetInstance.username}}'
          Contains: 'GetInstance.username'
        - NextStep: SetInstanceTagStatusPending
          And:
            - Variable: '{{GetInstance.state}}'
              StringEquals: running
            - Not:
                Variable: '{{GetInstance.username}}'
                Contains: 'GetInstance.username'     
      Default: exitWithFailure
  - name: SetInstanceTagStatusPending
    action: aws:executeAwsApi
    onFailure: step:exitWithFailure
    nextStep: SSM_ParameterStore_dcv_session_name
    inputs:
      Service: ec2
      Api: CreateTags
      Resources:
        - "{{GetInstance.InstanceId}}"
      Tags :
        - Key : "status-{{variable:tag}}"
          Value: "pending"
  - name: SSM_ParameterStore_dcv_session_name
    action: aws:executeAwsApi
    onFailure: step:SetInstanceTagStatusFailed
    nextStep: SSM_ParameterStore_dcv_session_type
    inputs:
      Api: GetParameter
      Service: ssm
      Name: /{{ prefix }}/dcv-session-name
      WithDecryption: true
    outputs:
      - Name: value
        Selector: $.Parameter.Value
        Type: String
  - name: SSM_ParameterStore_dcv_session_type
    action: aws:executeAwsApi
    onFailure: step:SetInstanceTagStatusFailed
    nextStep: ChooseOSforApplyCommands
    inputs:
      Api: GetParameter
      Service: ssm
      Name: /{{ prefix }}/dcv-session-type
      WithDecryption: true
    outputs:
      - Name: value
        Selector: $.Parameter.Value
        Type: String
  - name: ChooseOSforApplyCommands
    action: aws:branch
    onFailure: step:SetInstanceTagStatusFailed
    isEnd: false
    inputs:
      Choices:
      - NextStep: ApplyCommandsWindows
        Variable: "{{GetInstance.platform}}"
        StringEquals: windows
      - NextStep: ApplyCommandsLinux
        Variable: "{{GetInstance.platform}}"
        Contains: "GetInstance.platform"
      Default:
        SetInstanceTagStatusFailed
  - name: ApplyCommandsLinux
    action: aws:runCommand
    maxAttempts: 10
    timeoutSeconds: 600 
    onFailure: step:SetInstanceTagStatusFailed
    nextStep: SetInstanceTagStatusCompleted
    isEnd: false
    inputs:
      DocumentName: AWS-RunShellScript
      Targets:
        - Key: InstanceIds
          Values:
            - '{{GetInstance.InstanceId}}'
      Parameters:
        commands:
          - |
            set -e

            if [ -f /etc/os-release ]; then
                . /etc/os-release				
                OS_RELEASE="$ID.$VERSION_ID"
            elif [ -f /etc/centos-release ]; then
                OS_RELEASE="centos.$(awk '{print $3}' /etc/centos-release)"
            elif [ -f /etc/redhat-release ]; then
                OS_RELEASE="rhel.$(lsb_release -r | awk '{print $2}')"
            fi
            
            case "$OS_RELEASE" in
                amzn.2018.03|centos.6*|debian.9|rhel.6*|ubuntu.*)
                    command_path='/bin/'
                    ;;
                amzn.2*|centos.*|debian.*|fedora.*|rhel.*|sles*)
                    command_path='/usr/bin/'
                    ;;
                *)
                    # Catch all without the full path for untested platforms
                    command_path=''
            esac

            WriteStandardMessage() {
                "$command_path/echo" "$1"
            }
            
            ExitWithSuccessMessage() {
                WriteStandardMessage "$1"
                exit 0
            }

            WriteStandardMessage "Found OS_RELEASE: $OS_RELEASE" 'PRINT_JSON'

            WriteStandardMessage 'Restarting and enabling the NICE DCV Serser service...' 'PRINT_JSON'
            systemctl restart dcvserver
            systemctl enable  dcvserver

            WriteStandardMessage 'Restarting the NICE DCV Server session...' 'PRINT_JSON'
            dcv list-sessions | grep "Session: 'console' (owner:{{ GetInstance.username }} type:{{ SSM_ParameterStore_dcv_session_type.value }})" && dcv close-session --logout-user {{ SSM_ParameterStore_dcv_session_name.value }} || echo "no existing session found"
            dcv create-session --type={{ SSM_ParameterStore_dcv_session_type.value }} --owner {{ GetInstance.username }} {{ SSM_ParameterStore_dcv_session_name.value }}

            ExitWithSuccessMessage 'Failed to close existing and create a new NICE DCV sessions.' 'PRINT_JSON'
  - name: ApplyCommandsWindows
    action: aws:runCommand
    maxAttempts: 10
    timeoutSeconds: 600 
    onFailure: step:SetInstanceTagStatusFailed
    nextStep: SetInstanceTagStatusCompleted
    isEnd: false
    inputs:
      DocumentName: AWS-RunPowerShellScript
      Targets:
        - Key: InstanceIds
          Values:
            - '{{GetInstance.InstanceId}}'
      Parameters:
        commands:
          - |
            function ExitWithFailureMessage {
                param (
                    [string]$Message,
                    [string]$ExceptionMessage,
                    [Switch]$PrintJson
                )
                if ([string]::IsNullOrWhitespace($ExceptionMessage)) {
                    $errorMessage = $Message
                } else {
                    $errorMessage = '{0} {1}' -f $Message, $ExceptionMessage
                }
                if ($PrintJson) {ConvertTo-Json -InputObject @{error = $errorMessage} -Compress}
                WriteStandardError -Message $errorMessage
                [System.Environment]::Exit(1)
            }

            function ExitWithSuccessMessage {
                param (
                    [string]$Message
                )
                Write-Host $Message
                [System.Environment]::Exit(0)
            }

            try {
              Write-Host 'Restarting and enabling the NICE DCV Serser service...'              
              Restart-Service -Name "dcvserver"
              Set-Service dcvserver -startuptype automatic
            } catch {
                ExitWithFailureMessage -Message 'Failed to restart the NICE DCV Service.' -PrintJson
            }

            try {
              Write-Host 'Restarting the NICE DCV Server session...'
              Set-Location -Path "C:\Program Files\NICE\DCV\Server\bin\"
              .\dcv.exe close-session  --logout-user {{ SSM_ParameterStore_dcv_session_name.value }}
              .\dcv.exe create-session --type={{ SSM_ParameterStore_dcv_session_name.value }} --owner {{ GetInstance.username }} {{ SSM_ParameterStore_dcv_session_name.value }}
            } catch {
                ExitWithFailureMessage -Message 'Failed to close existing and create a new NICE DCV sessions.' -PrintJson
            }

            ExitWithSuccessMessage 'Completed the NICE DCV Server restart.' -PrintJson

  - name: SetInstanceTagStatusFailed
    action: aws:executeAwsApi
    onFailure: step:exitWithFailure
    nextStep: exitWithFailure
    inputs:
      Service: ec2
      Api: CreateTags
      Resources:
        - "{{GetInstance.InstanceId}}"
      Tags :
        - Key : "status-{{variable:tag}}"
          Value: "failed"
  - name: SetInstanceTagStatusCompleted
    action: aws:executeAwsApi
    onFailure: step:exitWithFailure
    nextStep: exitWithSuccess
    inputs:
      Service: ec2
      Api: CreateTags
      Resources:
        - "{{GetInstance.InstanceId}}"
      Tags :
        - Key : "status-{{variable:tag}}"
          Value: "completed"          
  - name: exitWithSuccess
    action: aws:sleep
    isEnd: true
    inputs:
      Duration: PT3S
  - name: exitWithFailure
    action: 'aws:executeScript'
    inputs:
        Runtime: "PowerShell Core 6.0"
        InputPayload:
            instanceId: '{{InstanceId}}'
        Script: |-
          exit -1
DOC
}
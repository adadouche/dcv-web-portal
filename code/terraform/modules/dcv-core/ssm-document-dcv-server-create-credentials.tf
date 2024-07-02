# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

resource "aws_ssm_document" "ssm_document_dcv_server_user_create" {
  name            = "${var.env.prefix}-nice-dcv-server-create-credentials"
  document_type   = "Automation"
  document_format = "YAML"
  target_type     = "/AWS::EC2::Instance"
  content         = <<DOC
description: |
  ## Create a user/pwd combination on the instance
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
    default: 'nice-dcv-server-create-credentials'
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
    nextStep: Secret_GetCredentials
    inputs:
      Service: ec2
      Api: CreateTags
      Resources:
        - '{{GetInstance.InstanceId}}'
      Tags :
        - Key : 'status-{{variable:tag}}'
          Value: 'pending'
  - name: Secret_GetCredentials
    action: aws:executeAwsApi
    nextStep: ChooseOSforApplyCommands
    isEnd: false
    onFailure: Abort
    inputs:
      Api: GetSecretValue
      Service: secretsmanager
      SecretId: '{{ prefix }}-{{ GetInstance.username }}-credentials'
    outputs:
      - Name: password
        Selector: $.SecretString
        Type: String
  - name: ChooseOSforApplyCommands
    action: aws:branch
    onFailure: step:SetInstanceTagStatusFailed
    isEnd: false
    inputs:
      Choices:
      - NextStep: ApplyCommandsWindows
        Variable: '{{GetInstance.platform}}'
        StringEquals: windows
      - NextStep: ApplyCommandsLinux
        Variable: '{{GetInstance.platform}}'
        Contains: 'GetInstance.platform'
      Default:
        SetInstanceTagStatusFailed
  - name: ApplyCommandsLinux
    action: aws:runCommand
    maxAttempts: 10
    timeoutSeconds: 600 
    onFailure: step:SetInstanceTagStatusFailed
    nextStep: SetInstanceTagStatusCompleted
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

            WriteStandardError() {
                MESSAGE="$1"
                (>&2 "$command_path/echo" "$MESSAGE")
            }
            
            WriteStandardMessage() {
                "$command_path/echo" "$1"
            }

            ExitWithFailureMessage() {
                MESSAGE="$1"
                JSON="$2"
                if [[ "$JSON" == "PRINT_JSON" ]]; then
                    "$command_path/echo" "{\"error\":\"$MESSAGE\"}"
                fi
                WriteStandardError "$MESSAGE"
                exit 1
            }
            
            # exit codes. 0-100 are reserved exit codes. 101-150 codes are for linux, 151-200 are for macos and 200 onwards codes are for windows.
            ExitWithFailureMessageAndExitCode() {
                MESSAGE="$1"
                EXITCODE="$2"
                JSON="$3"
                if [[ "$JSON" == "PRINT_JSON" ]]; then
                    "$command_path/echo" "{\"error\":\"$MESSAGE\",\"exitCode\":\"$EXITCODE\"}"
                fi
                WriteStandardError "$MESSAGE"
                exit "$EXITCODE"
            }
            
            ExitWithSuccessMessage() {
                WriteStandardMessage "$1"
                exit 0
            }

            WriteStandardMessage "Found OS_RELEASE: $OS_RELEASE" 'PRINT_JSON'
            
            if [ -f /usr/sbin/useradd ]; then
                COMMAND_ADD_USR='/usr/sbin/useradd'
                COMMAND_CHG_PWD='chpasswd'
            elif [ -f /usr/sbin/adduser ]; then
                COMMAND_ADD_USR='/usr/sbin/adduser'
                COMMAND_CHG_PWD='chpasswd'
            else
                ExitWithFailureMessage 'Neither of the required commands adduser or useradd exist.' 'PRINT_JSON'
            fi

            UserName='{{ GetInstance.username }}'
            UserPasswd='{{ Secret_GetCredentials.password }}'

            if [ $(getent group "$UserName") ]; then
              CREATE_USER_OPTS="-g $UserName"
            else
              CREATE_USER_OPTS=''
            fi

            case "$OS_RELEASE" in
                amzn.2*)
                    AdminGroup='wheel'
                    ;;
                *)
                    # Catch all without the full path for untested platforms
                    AdminGroup='sudo'
            esac

            if "$command_path/grep" -q "^$UserName:" /etc/passwd; then
                WriteStandardMessage 'The specified user already exists, doing nothing...' 'PRINT_JSON'
            else
                WriteStandardMessage 'The specified user doesn''t exists, creating...' 'PRINT_JSON'
                $COMMAND_ADD_USR $CREATE_USER_OPTS --comment "Local account for NICE DCV" "$UserName" || ExitWithFailureMessage 'Failed to create the $UserName user.' 'PRINT_JSON'
            fi

            WriteStandardMessage "Creating the home folder in case it doesn't exists" 'PRINT_JSON'
            mkdir -p /home/$UserName
            chown -R $UserName:$UserName /home/$UserName

            WriteStandardMessage "Setting the password" 'PRINT_JSON'
            echo "$UserName:$UserPasswd" | $COMMAND_CHG_PWD

            WriteStandardMessage "Adding user to $AdminGroup group" 'PRINT_JSON'
            usermod -a -G $AdminGroup "$UserName"

            ExitWithSuccessMessage 'Completed the NICE DCV Server user credentials creation.'

  - name: ApplyCommandsWindows
    action: 'aws:runCommand'
    maxAttempts: 10
    timeoutSeconds: 600 
    onFailure: step:SetInstanceTagStatusFailed
    nextStep: SetInstanceTagStatusCompleted
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
            
            function ExitWithFailureMessageAndExitCode {
                param (
                    [string]$Message,
                    [string]$ExceptionMessage,
                    [int]$ExitCode,
                    [Switch]$PrintJson
                )
                if ([string]::IsNullOrWhitespace($ExceptionMessage)) {
                    $errorMessage = $Message
                } else {
                    $errorMessage = '{0} {1}' -f $Message, $ExceptionMessage
                }
                if ($PSBoundParameters.ContainsKey('ExitCode') -eq $true) {
                    $exitCode = $ExitCode
                } else {
                    $exitCode = 1
                }
                if ($PrintJson) {
                    $ErrorObject = @{
                        error = $errorMessage
                        exitCode = $exitCode
                    }
                    ConvertTo-Json -InputObject $ErrorObject -Compress
                }
                WriteStandardError -Message $errorMessage
                [System.Environment]::Exit($exitCode)
            }
            
            function ExitWithSuccessMessage {
                param (
                    [string]$Message
                )
                Write-Host $Message
                [System.Environment]::Exit(0)
            }
            
            function WriteStandardError {
                param (
                    [string]$Message
                )
                $Host.UI.WriteErrorLine($Message)
            }

            Write-Host 'Creating OS credentials for the user [{{ GetInstance.username }}]...'

            $UserName   = "{{ GetInstance.username }}"
            $UserPswd   = ConvertTo-SecureString "{{ Secret_GetCredentials.password }}" -AsPlainText -Force
            $AdminGroup = "Administrators"

            try {
                Write-Host "Checking if user [{{ GetInstance.username }}] exists..."
                if ((Get-LocalUser "$UserName").Count -eq 0 ) {
                  Write-Host "Creating user [{{ GetInstance.username }}]..."
                  New-Localuser $UserName -Password $UserPswd -PasswordNeverExpires -AccountNeverExpires -Description "Local account for NICE DCV" -FullName "$UserName"
                } else {
                  Write-Host "The [{{ GetInstance.username }}] user already exists."
                }

                Write-Host "Checking if user [{{ GetInstance.username }}] is already part of [$AdminGroup] group..."
                if ( (Get-LocalGroupMember $AdminGroup).Name -contains "$env:computername\$UserName" ) {
                  Write-Host "The [{{ GetInstance.username }}] user is already part of the [$AdminGroup] group"
                } else {
                  Write-Host "Adding the [{{ GetInstance.username }}] user to the [$AdminGroup] group..."
                  Add-LocalGroupMember -Group "$AdminGroup" -Member "$UserName" -ErrorAction stop
                }
            } catch {
                Write-Host "Exception Failed to create the specified user [{{ GetInstance.username }}] and add it to the [$AdminGroup] group." -PrintJson
            }

            ExitWithSuccessMessage 'Completed the NICE DCV Server user credentials creation.' -PrintJson

  - name: SetInstanceTagStatusFailed
    action: aws:executeAwsApi
    onFailure: step:exitWithFailure
    nextStep: exitWithFailure
    inputs:
      Service: ec2
      Api: CreateTags
      Resources:
        - '{{GetInstance.InstanceId}}'
      Tags :
        - Key : 'status-{{variable:tag}}'
          Value: 'failed'
  - name: SetInstanceTagStatusCompleted
    action: aws:executeAwsApi
    onFailure: step:exitWithFailure
    nextStep: exitWithSuccess
    inputs:
      Service: ec2
      Api: CreateTags
      Resources:
        - '{{GetInstance.InstanceId}}'
      Tags :
        - Key : 'status-{{variable:tag}}'
          Value: 'completed'          
  - name: exitWithSuccess
    action: aws:sleep
    isEnd: true
    inputs:
      Duration: PT3S
  - name: exitWithFailure
    action: 'aws:executeScript'
    inputs:
        Runtime: 'PowerShell Core 6.0'
        InputPayload:
            instanceId: '{{InstanceId}}'
        Script: |-
          exit -1
DOC
}
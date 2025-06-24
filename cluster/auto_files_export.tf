resource "aws_ssm_document" "files_export" {
  name = "${var.name}-files-export"

  document_type   = "Automation"
  document_format = "YAML"

  content = yamlencode({
    schemaVersion = "0.3"

    assumeRole = aws_iam_role.automation.arn

    parameters = {
      site = {
        type        = "String"
        description = "Name of the site whose files are to be exported."
      }

      environment = {
        type        = "String"
        description = "Name of the environment (e.g., dev, stage) to be exported from EFS."
      }

      subdirectory = {
        type        = "String"
        description = "Name of the site's file directory to be exported (e.g., uploads)."
      }

      exportKey = {
        type        = "String"
        description = "Key in S3 to upload. Must be in .tar.gz format."
      }

      zzzInstanceAmiId = {
        type        = "String"
        default     = "{{ ssm:/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 }}"
        description = "Ignore this parameter; it is used to load the latest Amazon Linux 2023 AMI from AWS."
      }
    }

    mainSteps = [
      {
        name   = "Startup"
        action = "aws:runInstances"

        isEnd     = false
        onCancel  = "Abort"
        onFailure = "Abort"
        nextStep  = "RunCommandOnInstances"

        inputs = {
          ImageId               = "{{ zzzInstanceAmiId }}"
          InstanceType          = "t3a.medium"
          SubnetId              = module.vpc.private_subnets[0]
          SecurityGroupIds      = [aws_security_group.automation_ec2.id]
          IamInstanceProfileArn = aws_iam_instance_profile.automation_ec2.arn

          BlockDeviceMappings = [
            {
              DeviceName = "/dev/xvda"

              Ebs = {
                VolumeSize = 512
              }
            }
          ]

          TagSpecifications = [
            {
              ResourceType = "instance"

              Tags = concat(local.tag_list, [
                {
                  Key   = "Name"
                  Value = "EFS Export/{{ automation:EXECUTION_ID }}"
                },
                {
                  Key   = "forumone:site"
                  Value = "{{ site }}"
                },
                {
                  Key   = "forumone:environment"
                  Value = "{{ environment }}"
                }
              ])
            }
          ]
        }
      },
      {
        name   = "RunCommandOnInstances"
        action = "aws:runCommand"

        isEnd     = false
        onCancel  = "step:Cleanup"
        onFailure = "step:Cleanup"
        nextStep  = "Cleanup"

        inputs = {
          DocumentName = "AWS-RunShellScript"
          InstanceIds  = "{{ Startup.InstanceIds }}"

          Parameters = {
            commands = [
              # Add necessary packages
              "dnf install -y amazon-efs-utils",

              # Mount the EFS file system
              "fsid=\"$(aws --region=${data.aws_region.current.name} ssm get-parameter --name=\"/${var.name}/applications/{{ site }}/efs/filesystem\" --query=Parameter.Value --out=text)\"",
              "mkdir -p /mnt/efs",
              "mount -t efs -o tls,iam,ro $fsid /mnt/efs",

              # Create the tarball
              "tar czf files.tar.gz -C /mnt/efs/{{ environment }}/{{ subdirectory }} .",

              # Push up
              "aws s3 cp files.tar.gz s3://${var.automation.transfer_bucket_name}/{{ exportKey }}.tar.gz",
            ]

            workingDirectory = "/var/tmp"
          }
        }
      },
      {
        name   = "Cleanup"
        action = "aws:changeInstanceState"

        isEnd = true

        inputs = {
          DesiredState = "terminated"
          InstanceIds  = "{{ Startup.InstanceIds }}"
        }
      }
    ]
  })

  tags = {
    "forumone:cluster" = var.name
  }
}

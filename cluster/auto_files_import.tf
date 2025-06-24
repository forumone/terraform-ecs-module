resource "aws_ssm_document" "files_import" {
  name = "${var.name}-files-import"

  document_type   = "Automation"
  document_format = "YAML"

  content = yamlencode({
    schemaVersion = "0.3"

    assumeRole = aws_iam_role.automation.arn

    parameters = {
      site = {
        type        = "String"
        description = "Name of the site whose files are to be import."
      }

      environment = {
        type        = "String"
        description = "Name of the environment (e.g., dev, stage) to be exported from MySQL."
      }

      subdirectory = {
        type        = "String"
        description = "Name of the site's file directory to be exported (e.g., uploads)."
      }

      deleteOnSync = {
        type          = "String"
        default       = "false"
        description   = "If the file import process should delete files not present in the downloaded archive."
        allowedValues = ["true", "false"]
      }

      importKey = {
        type        = "String"
        description = "Key in S3 to download. Must be in .tar.gz format."
      }

      zzzInstanceAmiId = {
        type        = "String"
        default     = "{{ ssm:/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64 }}"
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
                VolumeSize = 4096
              }
            }
          ]

          TagSpecifications = [
            {
              ResourceType = "instance"

              Tags = concat(local.tag_list, [
                {
                  Key   = "Name"
                  Value = "EFS Import/{{ automation:EXECUTION_ID }}"
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

              # Download the files tarball
              "aws s3 cp s3://${var.automation.transfer_bucket_name}/{{ importKey }}.tar.gz files.tar.gz",

              # Mount the EFS file system
              "fsid=\"$(aws --region=${data.aws_region.current.name} ssm get-parameter --name=\"/${var.name}/applications/{{ site }}/efs/filesystem\" --query=Parameter.Value --out=text)\"",
              "mkdir -p /mnt/efs",
              "mount -t efs -o tls,iam $fsid /mnt/efs",

              # Set up rsync flags doing file export
              # "if test \"{{ deleteOnSync }}\" = true; then delete=--delete; else delete=",

              # Unpack files to a subdirectory of /tmp
              "mkdir /tmp/files",
              "tar zxf files.tar.gz -C /tmp/files",

              # Run rsync recursively (ignoring ownership)
              "chown -R ec2-user:ec2-user /mnt/efs/{{ environment }}/{{subdirectory }}/",
              "rsync --archive $delete --no-owner /tmp/files/ /mnt/efs/{{ environment }}/{{subdirectory }}/",
              "chown -R ec2-user:ec2-user /mnt/efs/{{ environment }}/{{subdirectory }}/"
            ]

            workingDirectory = "/tmp"
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

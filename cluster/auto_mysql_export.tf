resource "aws_ssm_document" "mysql_export" {
  name = "${var.name}-mysql-export"

  document_type   = "Automation"
  document_format = "YAML"

  content = yamlencode({
    schemaVersion = "0.3"

    assumeRole = aws_iam_role.automation.arn

    parameters = {
      site = {
        type        = "String"
        description = "Name of the site to be exported from MySQL."
      }

      database = {
        type        = "String"
        default     = "web"
        description = "Name of the site's DB to be exported. The default is fine in most cases."
      }

      environment = {
        type        = "String"
        description = "Name of the environment (e.g., dev, stage) to be exported from MySQL."
      }

      exportKey = {
        type        = "String"
        description = "Name of the key to export to in S3. Will be in .sql.gz format."
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
                VolumeSize = 128
              }
            }
          ]

          TagSpecifications = [
            {
              ResourceType = "instance"

              Tags = concat(local.tag_list, [
                {
                  Key   = "Name"
                  Value = "MySQL Export/{{ automation:EXECUTION_ID }}"
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
              "dnf install -y docker jq",
              "systemctl start docker.service",

              # Download the MySQL 8.0 Docker image
              "docker pull -q mysql:8.0",

              # Convert Secrets Manager credentials into regular-flavor MySQL configuration
              "aws --region=${data.aws_region.current.name} secretsmanager get-secret-value --secret-id=/${var.name}/{{ site }}/{{ environment }}/{{ database }} >cred.json",
              "echo '[client]' >/etc/my.cnf",
              "echo -n 'host=' && jq -r '.SecretString' cred.json | jq -r .host >>/etc/my.cnf",
              "echo -n 'port=' && jq -r '.SecretString' cred.json | jq -r .port >>/etc/my.cnf",
              "echo -n 'user=' && jq -r '.SecretString' cred.json | jq -r .user >>/etc/my.cnf",
              "echo -n 'password=' && jq -r '.SecretString' cred.json | jq -r .password >>/etc/my.cnf",

              # Run `mysqldump` against the DB
              # "docker run --rm -v /etc/my.cnf:/etc/my.cnf:ro mysql:8.0 mysqldump --set-gtid-purged=OFF --no-tablespaces {{ site }}-{{ environment }}-{{ database }} >dump.sql",

              # Compress the dump
              "gzip dump.sql",

              # Export the dump to
              "aws s3 cp dump.sql.gz s3://${var.automation.transfer_bucket_name}/{{ exportKey }}.sql.gz"
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

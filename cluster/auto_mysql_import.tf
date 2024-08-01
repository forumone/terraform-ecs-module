resource "aws_ssm_document" "mysql_import" {
  name = "${var.name}-mysql-import"

  document_type   = "Automation"
  document_format = "YAML"

  content = yamlencode({
    schemaVersion = "0.3"

    assumeRole = aws_iam_role.automation.arn

    parameters = {
      site = {
        type        = "String"
        description = "Name of the site to be imported into MySQL."
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

      dropBeforeImport = {
        type          = "String"
        default       = "false"
        description   = "Whether or not to drop all tables before import. Sometimes needed to fully wipe a database."
        allowedValues = ["true", "false"]
      }

      importKey = {
        type        = "String"
        description = "Key in S3 to download. Must be in .sql.gz format."
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
          ImageId          = "{{ zzzInstanceAmiId }}"
          InstanceType     = "t3a.medium"
          SubnetId         = module.vpc.private_subnets[0]
          SecurityGroupIds = [aws_security_group.automation_ec2.id]

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
                  Value = "MySQL Import/{{ automation:EXECUTION_ID }}"
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
              "jq -r \"host=\\(.host)\" >>/etc/my.cnf",
              "jq -r \"port=\\(.port)\" >>/etc/my.cnf",
              "jq -r \"user=\\(.username)\" >>/etc/my.cnf",
              "jq -r \"password=\\(.password)\" >>/etc/my.cnf",

              # Download and decompress dump
              "aws s3 cp s3://${var.automation.transfer_bucket_name}/{{ importKey }}.sql.gz dump.sql.gz",
              "gunzip dump.sql.gz",

              # If we were asked to drop tables before import, then drop them here
              "if test \"{{ dropBeforeImport }}\" = true; then",
              "  docker run --rm -it -v /etc/my.cnf:/etc/my.cnf:ro mysql:8.0 mysqlshow \"{{ site }}-{{ environment }}-{{ database }}\" | while read line; do",
              "    docker run --rm -it -v /etc/my.cnf:/etc/my.cnf:ro mysql:8.0 mysql --batch --execute \"DROP TABLE $line\"",
              "  done",
              "fi",

              # Run `mysqldump` against the DB
              "docker run --rm -it -v /etc/my.cnf:/etc/my.cnf:ro mysql:8.0 mysql --batch \"{{ site }}-{{ environment }}-{{ database }}\" <dump.sql",
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

  tags = local.tags
}

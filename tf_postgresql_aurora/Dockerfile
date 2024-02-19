# Keep this in sync with the required_version in providers.tf
FROM hashicorp/terraform:1.6.6

WORKDIR /app

# Modify runs within this container:
# 1. Tell Terraform this is an unattended run
# 2. Prevent Terraform from asking for input
# 3. Add the -no-color flag automatically to prevent ANSI escape codes from
#    being present in the CloudWatch output
ENV TF_IN_AUTOMATION=1 TF_INPUT=0 TF_CLI_ARGS=-no-color

COPY *.tf ./
RUN terraform init -backend=false

# Perform a build-time check to ensure we didn't do something dumb
RUN terraform validate

ENTRYPOINT \
  set -exu \
  && terraform init \
    -backend-config="bucket=$BACKEND_STORAGE" \
    -backend-config="dynamodb_table=$BACKEND_LOCKS" \
  && terraform plan -out plan \
  && terraform apply plan

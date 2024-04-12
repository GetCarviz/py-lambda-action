FROM --platform=linux/arm64 public.ecr.aws/lambda/python:3.11-arm64

# Use yum to update and install packages
RUN yum update -y
RUN yum install -y jq zip

# Upgrade pip and install awscli
RUN python -m pip install --upgrade pip
RUN pip install awscli

# Add the entrypoint script
ADD entrypoint.sh /entrypoint.sh

# Set the entrypoint
ENTRYPOINT ["/entrypoint.sh"]

# dONE
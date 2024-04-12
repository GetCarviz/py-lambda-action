FROM --platform=linux/arm64 public.ecr.aws/lambda/python:3.12-arm64

RUN apt-get update
RUN apt-get install -y jq zip
RUN python -m pip install --upgrade pip
RUN pip install awscli

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

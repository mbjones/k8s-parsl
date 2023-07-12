# Build an image to run parsl. Include any requirements from your application.
# e.g., docker build -t ghcr.io/mbjones/k8sparsl:0.1 .
FROM ubuntu:20.04

# Connect this image to a GitHub repository
LABEL org.opencontainers.image.source https://github.com/mbjones/k8s-parsl

# Install base software packages
RUN apt update && \
    apt install -y python3.9 python3.9-venv python3.9-distutils curl bind9-host netcat-openbsd iproute2 iputils-ping

RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py

RUN python3.9 get-pip.py

# Configure the application
WORKDIR /home/k8sparsl

COPY requirements.txt .

RUN pip install -r requirements.txt

COPY *.py .

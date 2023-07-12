# Build an image to run parsl. Include any requirements from your application.
# e.g., docker build -t ghcr.io/mbjones/k8sparsl:0.3 .
FROM ubuntu:22.04

# Connect this image to a GitHub repository
LABEL org.opencontainers.image.source https://github.com/mbjones/k8s-parsl

# Install base software packages
RUN apt update && \
    apt install -y python3.10 python3.10-venv python3.10-distutils curl bind9-host netcat-openbsd iproute2 iputils-ping

RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py

RUN python3.10 get-pip.py

# Configure the application
WORKDIR /home/k8sparsl

COPY requirements.txt .

RUN pip install -r requirements.txt

COPY *.py .

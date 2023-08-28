FROM quay.io/argoproj/argocd:v2.8.2

USER root

RUN apt-get update
RUN apt-get install -y curl unzip groff

# Install NodeJS
RUN curl -fssL https://deb.nodesource.com/setup_20.x | bash -
RUN apt-get install -y nodejs

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" &&  unzip awscliv2.zip && ./aws/install

RUN apt-get clean

RUN npm install -g cdk8s-cli

USER $ARGOCD_USER_ID


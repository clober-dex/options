FROM ubuntu:20.04

# install nodejs
RUN apt-get -qq update
RUN apt-get -qq upgrade --yes
RUN apt-get -qq install curl git build-essential --yes
RUN curl -sL https://deb.nodesource.com/setup_18.x | bash -
RUN apt-get -qq install nodejs --yes
WORKDIR /app
COPY . /app

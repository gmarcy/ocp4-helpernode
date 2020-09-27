FROM docker.io/centos:8

ARG USER=helper
ARG HOME=/home/helper
ARG PULL_SECRET=pull-secret
ARG VARS_YAML=vars.yaml

USER root

RUN groupadd --gid 1000 helper

RUN useradd --uid 1000 --gid helper --shell /bin/bash --create-home $USER

RUN dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm \
  && dnf install -y ansible git \
  && dnf update -y; dnf clean all

RUN mkdir -p $HOME

WORKDIR $HOME

RUN git clone https://github.com/gmarcy/ocp4-helpernode

WORKDIR $HOME/ocp4-helpernode

RUN git pull origin okd_support

RUN mkdir $HOME/.openshift

COPY $PULL_SECRET $HOME/.openshift/pull-secret

COPY $VARS_YAML .

ENV USER=$USER
ENV HOME=$HOME

RUN ansible-playbook -e @vars.yaml tasks/container-main.yml

WORKDIR $HOME/ocp4

RUN openshift-install create manifests

RUN sed -i 's/mastersSchedulable: true/mastersSchedulable: false/g' manifests/cluster-scheduler-02-config.yml

RUN openshift-install create ignition-configs

RUN cp $HOME/ocp4/*.ign /var/www/html/ignition/

RUN chmod o+r /var/www/html/ignition/*.ign


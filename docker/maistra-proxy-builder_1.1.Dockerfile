# Hack: Remove this once the base image has go 1.16
FROM golang:1.16.4 AS go116

ENV K8S_TEST_INFRA_VERSION=5763223177
RUN git clone https://github.com/kubernetes/test-infra.git /root/test-infra && \
    cd /root/test-infra && git checkout ${K8S_TEST_INFRA_VERSION} && \
    go build -o /usr/local/bin/checkconfig prow/cmd/checkconfig/main.go && \
    go build -o /usr/local/bin/pr-creator robots/pr-creator/main.go

FROM centos:8

# Versions
ENV K8S_TEST_INFRA_VERSION=5763223177

RUN dnf -y upgrade --refresh && \
    dnf -y install dnf-plugins-core https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm && \
    dnf -y config-manager --set-enabled powertools && \
    dnf -y install git make libtool patch libatomic which \
                   autoconf automake libtool cmake python2 python3 \
                   gcc gcc-c++ ninja-build golang annobin libstdc++-static \
                   java-11-openjdk-devel jq file diffutils && \
    dnf -y clean all

# Bazel
RUN curl -o /usr/bin/bazel -Ls https://github.com/bazelbuild/bazel/releases/download/1.1.0/bazel-1.1.0-linux-x86_64 && \
    chmod +x /usr/bin/bazel

# Go tools
# Hack: Revert this once the base image has go 1.16
# RUN git clone https://github.com/kubernetes/test-infra.git /root/test-infra && \
#     cd /root/test-infra && git checkout ${K8S_TEST_INFRA_VERSION} && \
#     go build -o /usr/local/bin/checkconfig prow/cmd/checkconfig/main.go && \
#     go build -o /usr/local/bin/pr-creator robots/pr-creator/main.go && \
#     rm -rf /root/* /root/.cache /tmp/*
COPY --from=go116 /usr/local/bin/pr-creator /usr/local/bin/pr-creator
COPY --from=go116 /usr/local/bin/checkconfig /usr/local/bin/checkconfig

ENV CC=gcc CXX=g++ USER=user HOME=/home/user
RUN mkdir -p /home/user && chmod 777 /home/user

WORKDIR /work

RUN ln -s /usr/bin/python3 /usr/bin/python

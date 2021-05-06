FROM alpine:latest

# Install packages
RUN apk update
RUN apk add \
	bash sudo tar vim dialog iptables curl wget tmux git \
	util-linux \
	iputils \
	iproute2 \
	build-base \
	python3 python3-dev py3-pip \
	openssh-client \
	openssl openssl-dev \
	libffi-dev \
	xz-dev \
	cargo \
	openrc \
	nfs-utils \
	gdb-multiarch \
	squashfs-tools \
	cramfs \
	--no-cache

# Install Python packages
RUN pip install --upgrade pip
RUN pip install wheel
RUN pip install cstruct
RUN pip install pwntools

# Install packages/repos from Github
WORKDIR /tmp
RUN git clone --depth 1 https://github.com/sviehb/jefferson.git
RUN git clone --depth 1 https://github.com/ReFirmLabs/binwalk.git

WORKDIR /tmp/jefferson
RUN python3 setup.py install

WORKDIR /tmp/binwalk
RUN python3 setup.py install

# Copy network tunnel startup script and NFS exports
COPY files/etc/local.d/10-tun-network.start /etc/local.d/10-tun-network.start
COPY files/etc/exports /etc/exports
RUN chmod 755 /etc/local.d/10-tun-network.start

# Create an r0 user for all userland work
RUN adduser --disabled-password --gecos "" r0
RUN echo 'r0 ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# Set r0's shell to bash
RUN sed -i 's!/bin/ash!/bin/bash!g' /etc/passwd

# Set up the home directory of r0 user
WORKDIR /home/r0

# Add bashrc, ssh configs, etc
COPY --chown=r0 files/home/r0/bashrc .bashrc
COPY --chown=r0 files/home/r0/bash_profile .bash_profile
COPY --chown=r0 files/home/r0/tmux.conf .tmux.conf
COPY --chown=r0 files/home/r0/ssh .ssh
COPY --chown=root files/home/r0/bashrc /root/.bashrc
COPY --chown=root files/home/r0/bash_profile /root/.bash_profile
COPY --chown=root files/home/r0/tmux.conf /root/.tmux.conf
COPY --chown=root files/home/r0/ssh /root/.ssh

RUN chmod 600 /home/r0/.ssh/id_rsa
RUN chmod 600 /root/.ssh/id_rsa

# Set up the docker entrypoint script
COPY ./docker-entrypoint.sh /usr/local/bin

USER r0

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["/bin/bash"]

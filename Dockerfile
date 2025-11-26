FROM ubuntu:22.04
LABEL maintainer="Peter Mescalchin <peter@magnetikonline.com>"

ARG ACE_STREAM_VERSION

RUN DEBIAN_FRONTEND="noninteractive" \
	apt-get update && apt-get --yes upgrade && \
	# install packages
	apt-get --no-install-recommends --yes install \
		curl \
		build-essential \
				libpython3.10-dev \
				libssl-dev \
				net-tools \
				python3.10-dev \
		python3-lxml \
		python3-pip \
		swig \
		&& \
	pip3 install --upgrade pip setuptools==68.0.0 && \
	pip3 install apsw M2Crypto && \
	# clean up
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*

RUN \
	# install server
	curl --silent --location "https://download.acestream.media/linux/acestream_${ACE_STREAM_VERSION}.tar.gz" -o /tmp/acestream.tar.gz && \
	mkdir -p /opt/acestream && \
	tar -xzf /tmp/acestream.tar.gz -C /opt/acestream --strip-components=1 && \
	rm /tmp/acestream.tar.gz

RUN \
	echo '#!/bin/bash' > /start-engine && \
	echo 'exec /opt/acestream/acestreamengine/CoreApp.so "$@"' >> /start-engine && \
	chmod +x /start-engine

EXPOSE 6878/tcp

ENTRYPOINT ["/start-engine"]
CMD ["--client-console"]

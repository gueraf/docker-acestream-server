FROM debian:bullseye-slim
LABEL maintainer="Peter Mescalchin <peter@magnetikonline.com>"

ARG ACE_STREAM_VERSION

RUN DEBIAN_FRONTEND="noninteractive" \
	apt-get update && apt-get --yes upgrade && \
	# install packages
	apt-get --no-install-recommends --yes install \
		curl \
		build-essential \
		libpython3-dev \
		libssl-dev \
		net-tools \
		python3-dev \
		python3-lxml \
		python3-pip \
		swig \
		&& \
	pip3 install apsw M2Crypto && \
	# clean up
	apt-get clean && \
	rm --force --recursive /var/lib/apt/lists

RUN \
	# install server
	curl --silent "https://download.acestream.media/linux/acestream_${ACE_STREAM_VERSION}_x86_64.tar.gz" | \
		tar --extract --gzip

EXPOSE 6878/tcp

ENTRYPOINT ["/start-engine"]
CMD ["--client-console"]

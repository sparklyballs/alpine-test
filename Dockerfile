ARG ALPINE_VER="3.9"
FROM alpine:${ALPINE_VER} as fetch-stage

############## fetch stage ##############

# install fetch packages
RUN \
	apk add --no-cache \
	bash \
	curl \
	jq \
	tar

# set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# fetch overlay
RUN \
	set -ex \
	&& mkdir -p \
		/overlay-src \
	&& OVERLAY_RELEASE=$(curl -sX GET "https://api.github.com/repos/just-containers/s6-overlay/releases/latest" \
		| jq -r .tag_name) \
	&& curl -o \
	/tmp/overlay.tar.gz -L \
	"https://github.com/just-containers/s6-overlay/releases/download/${OVERLAY_RELEASE}/s6-overlay-amd64.tar.gz" \
	&& tar xf \
	/tmp/overlay.tar.gz -C \
	/overlay-src --strip-components=1

FROM alpine:${ALPINE_VER}

############## runtime stage ##############

# environment variables
ENV PS1="$(whoami)@$(hostname):$(pwd)$ " \
HOME="/root" \
TERM="xterm"

# install runtime packages
RUN \
	apk add --no-cache \
		bash \
		ca-certificates \
		coreutils \
		shadow \
		tzdata

# create user and folders
RUN \
	set -ex \
	&& groupmod -g 1000 users \
	&& useradd -u 911 -U -d /config -s /bin/false abc \
	&& usermod -G users abc \
	&& mkdir -p \
		/app \
		/config \
		/defaults


# add artifacts from fetch stage
COPY --from=fetch-stage /overlay-src/ /

# add local files
COPY root/ /

ENTRYPOINT ["/init"]

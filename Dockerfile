# hadolint global ignore=DL3006
ARG RELEASE=alpine:3.18
FROM $RELEASE as fetch-stage

############## fetch stage ##############

# build args
ARG S6_OVERLAY_RELEASE
ARG OVERLAY_ARCH="x86_64"

# install fetch packages
RUN \
	apk add --no-cache \
	bash \
	curl

# set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# fetch version file
RUN \
	set -ex \
	&& curl -o \
	/tmp/version.txt -L \
	"https://raw.githubusercontent.com/sparklyballs/versioning/master/version.txt"

# fetch overlay
# hadolint ignore=SC1091
RUN \
	. /tmp/version.txt \
	&& set -ex \
	&& mkdir -p \
		/src/overlay \
	&& curl -o \
	/tmp/overlay.tar.xz -L \
	"https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_RELEASE}/s6-overlay-${OVERLAY_ARCH}.tar.xz" \
	&& curl -o \
	/tmp/noarch.tar.xz -L \
	"https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_RELEASE}/s6-overlay-noarch.tar.xz" \
	&& curl -o \
	/tmp/symlinks.tar.xz -L \
	"https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_RELEASE}/s6-overlay-symlinks-noarch.tar.xz" \
	&& tar xf \
	/tmp/overlay.tar.xz -C \
	/src/overlay \
	&& tar xf \
	/tmp/noarch.tar.xz -C \
	/src/overlay \
	&& tar xf \
	/tmp/symlinks.tar.xz -C \
	/src/overlay

FROM $RELEASE

############## runtime stage ##############

# environment variables
ENV PS1="$(whoami)@$(hostname):$(pwd)$ " \
HOME="/root" \
TERM="xterm" \
PATH=/usr/sbin:$PATH

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
COPY --from=fetch-stage /src/overlay/ /

# add local files
COPY root/ /

ENTRYPOINT ["/init"]

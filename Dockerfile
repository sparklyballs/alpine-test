ARG ALPINE_VER="3.14"
FROM alpine:${ALPINE_VER} as fetch-stage

############## fetch stage ##############

# overlay arch
ARG OVERLAY_ARCH="amd64"

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
		/overlay-src \
	&& curl -o \
	/tmp/overlay.tar.gz -L \
	"https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_RELEASE}/s6-overlay-${OVERLAY_ARCH}.tar.gz" \
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

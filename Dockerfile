FROM webratio/ant
FROM openjdk:11.0.3-jdk-slim-stretch
#Add adbs directory to $HOME/src
ADD ./adbs/ $HOME/src/adbs/

# Installs i386 architecture required for running 32 bit Android tools
RUN dpkg --add-architecture i386 && \
    apt-get update -y && \
    apt-get install -y libc6:i386 libncurses5:i386 libstdc++6:i386 lib32z1 wget rubygems && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get autoremove -y && \
    apt-get clean

# Installs Android SDK
ENV ANDROID_SDK_FILENAME android-sdk_r24.4.1-linux.tgz
ENV ANDROID_SDK_URL http://dl.google.com/android/${ANDROID_SDK_FILENAME}
ENV ANDROID_API_LEVELS android-21
ENV ANDROID_BUILD_TOOLS_VERSION 21.1.0
ENV ANDROID_HOME /opt/android-sdk-linux
ENV PATH ${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools
RUN cd /opt && \
    wget -q ${ANDROID_SDK_URL} && \
    tar -xzf ${ANDROID_SDK_FILENAME} && \
    rm ${ANDROID_SDK_FILENAME} && \
    echo y | android update sdk --no-ui -a --filter tools,platform-tools,${ANDROID_API_LEVELS},build-tools-${ANDROID_BUILD_TOOLS_VERSION}

# Copying different versions of adb to ${ANDROID_HOME}/platform-tools
RUN echo "Copying different versions of adb to ${ANDROID_HOME}/platform-tools"
RUN cp /src/adbs/adb-8aug-usbbus-maxemu-v39 ${ANDROID_HOME}/platform-tools/adb-8aug-usbbus-maxemu-v39
RUN cp /src/adbs/adb-7aug-usbbus-maxemu-v40 ${ANDROID_HOME}/platform-tools/adb-7aug-usbbus-maxemu-v40

# Install Ruby with dependencies
RUN apt-get update
RUN apt-get install -y build-essential
RUN apt-get install -y libssl-dev
RUN apt-get install -y git-core
RUN apt-get install -y curl
RUN apt-get clean

RUN apt-get update && apt-get install -y --no-install-recommends \
		autoconf \
		automake \
		bzip2 \
		file \
		g++ \
		gcc \
		imagemagick \
		libbz2-dev \
		libc6-dev \
		libcurl4-openssl-dev \
		libdb-dev \
		libevent-dev \
		libffi-dev \
		libgeoip-dev \
		libglib2.0-dev \
		libjpeg-dev \
		libkrb5-dev \
		liblzma-dev \
		libmagickcore-dev \
		libmagickwand-dev \
		default-libmysqlclient-dev \
		libncurses-dev \
		libpng-dev \
		libpq-dev \
		libreadline-dev \
		libsqlite3-dev \
		libssl-dev \
		libtool \
		libwebp-dev \
		libxml2-dev \
		libxslt-dev \
		libyaml-dev \
		make \
		patch \
		xz-utils \
		zlib1g-dev \
		jq \
		rubygems \ 
		zip \
		net-tools \
		iputils-ping \
	&& rm -rf /var/lib/apt/lists/*

	RUN apt-get install -y curl \
  && curl -sL https://deb.nodesource.com/setup_9.x | bash - \
  && apt-get install -y nodejs \
  && curl -L https://www.npmjs.com/install.sh | sh

	# skip installing gem documentation
RUN mkdir -p /usr/local/etc \
	&& { \
		echo 'install: --no-document'; \
		echo 'update: --no-document'; \
	} >> /usr/local/etc/gemrc

RUN apt-get update && apt-get install -y curl procps && rm -rf /var/lib/apt/lists/*

ENV RUBY_MAJOR 2.6
ENV RUBY_VERSION 2.6.3

# some of ruby's build scripts are written in ruby
# we purge this later to make sure our final image uses what we just built
RUN apt-get update \
	&& apt-get install -y bison ruby \
	&& rm -rf /var/lib/apt/lists/* \
	&& mkdir -p /usr/src/ruby \
	&& curl -SL "http://cache.ruby-lang.org/pub/ruby/$RUBY_MAJOR/ruby-$RUBY_VERSION.tar.bz2" \
		| tar -xjC /usr/src/ruby --strip-components=1 \
	&& cd /usr/src/ruby \
	&& autoconf \
	&& ./configure --disable-install-doc \
	&& make -j"$(nproc)" \
	&& apt-get purge -y --auto-remove bison ruby \
	&& make install \
	&& rm -r /usr/src/ruby

# skip installing gem documentation
RUN echo 'gem: --no-rdoc --no-ri' >> "$HOME/.gemrc"

# install things globally, for great justice
ENV GEM_HOME /usr/local/bundle
ENV PATH $GEM_HOME/bin:$PATH
RUN gem install bundler rake \
	&& bundle config --global path "$GEM_HOME" \
	&& bundle config --global bin "$GEM_HOME/bin"

# Disable ipv6 as docker container not able make network calls in ipv4.
echo precedence ::ffff:0:0/96  100 >> /etc/gai.conf

# don't create ".bundle" in all our apps
ENV BUNDLE_APP_CONFIG $GEM_HOME

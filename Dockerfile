FROM ubuntu:18.04

############
# OS setup #
############


## Let apt-get know we are running in noninteractive mode
ENV DEBIAN_FRONTEND noninteractive

## Make sure image is up-to-date
RUN apt-get update \
    && apt-get -y upgrade \
    && apt-get -y install curl wget gnupg software-properties-common libsdl2-2.0-0 libc6\
    && add-apt-repository --remove 'deb https://download.opensuse.org/repositories/Emulators:/Wine:/Debian/Ubuntu_18.10_standard ./'


##############
# Wine setup #
##############

## Enable 32 bit architecture for 64 bit systems
RUN dpkg --add-architecture i386

## Wine now depends on libfaudio0, but Ubuntu versions prior to 19.10 don't include it in the standard repositories.
## The link to the Winehq forum page with directions on how to install the packages is:
## https://forum.winehq.org/viewtopic.php?f=8&t=32192.
## FROM: https://askubuntu.com/questions/1100351/broken-packages-fix-problem-for-wine
RUN wget https://download.opensuse.org/repositories/Emulators:/Wine:/Debian/xUbuntu_18.04/amd64/libfaudio0_19.07-0~bionic_amd64.deb \
    && dpkg -i libfaudio0_19.07-0~bionic_amd64.deb

## Add wine repository
RUN wget -nc https://dl.winehq.org/wine-builds/winehq.key \
    && apt-key add winehq.key \
    && wget -qO- https://dl.winehq.org/wine-builds/Release.key | apt-key add - \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys DFA175A75104960E \
    && add-apt-repository 'deb https://download.opensuse.org/repositories/Emulators:/Wine:/Debian/xUbuntu_18.04/ ./' \
    && add-apt-repository 'deb http://dl.winehq.org/wine-builds/ubuntu/ bionic main' \
    && apt-get update \
    && apt-get autoremove


## Install wine and winetricks
RUN apt-get -f -y install --install-recommends winehq-stable xvfb

## Setup GOSU to match user and group ids
##
## User: user
## Pass: 123
##
## Note that this setup also relies on entrypoint.sh
## Set LOCAL_USER_ID as an ENV variable at launch or the default uid 9001 will be used
## Set LOCAL_GROUP_ID as an ENV variable at launch or the default uid 250 will be used
## (e.g. docker run -e LOCAL_USER_ID=151149 ....)
##
## Initial password for user will be 123
ENV GOSU_VERSION 1.9
RUN set -x \
    && apt-get update && apt-get install -y --no-install-recommends ca-certificates wget && rm -rf /var/lib/apt/lists/* \
    && dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"

## If building fails here, just restart build untill it's done
RUN export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true

RUN addgroup --gid 111 userg
RUN useradd --shell /bin/bash -c "" -m user -u 107 -g 111
ENV HOME /home/user
RUN chown -R user:userg $HOME
RUN chmod -R a+rwx $HOME
RUN echo 'user:123' | chpasswd
USER user
ENV WINEPREFIX /home/user
ENV WINEARCH win32

RUN wineboot --init

RUN curl -SL "http://www.jrsoftware.org/download.php/is.exe" -o ~/is.exe

## IMPORTANT: need to run container after build and execute command below this comment
## when installation will be completed, you'll need to commit container and only then push it to docker.hub
##
## Xvfb :0 -screen 0 1024x768x16 &
## export DISPLAY=:0.0
## wine ~/is.exe /VERYSILENT /SUPPRESSMSGBOXES /ALLUSERS /SP- /DIR="C:\\innosetup"

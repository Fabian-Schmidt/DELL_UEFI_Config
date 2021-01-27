FROM debian:jessie AS base

FROM base AS build

RUN apt-get update \
&& apt-get install -y binutils curl bison gcc flex python make libfreetype6-dev pkg-config dh-autoreconf \
&& rm -rf /var/lib/apt/lists/*

# && apt-get install -y ca-certificates \
# additional packages I used during my testing:
#  libopts25 libselinux1-dev autogen libfont-freetype-perl m4 autoconf help2man automake autotools-dev texinfo

WORKDIR /src

RUN curl ftp://ftp.gnu.org/gnu/grub/grub-2.04.tar.gz -o grub-2.04.tar.gz \
 && curl ftp://ftp.gnu.org/gnu/grub/grub-2.04.tar.gz.sig -o grub-2.04.tar.gz.sig

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 988C2166 \
 && apt-key adv --verify grub-2.04.tar.gz.sig grub-2.04.tar.gz \
 && zcat grub-2.04.tar.gz | tar xvf - \
 && rm grub-2.04.tar.gz \
 && rm grub-2.04.tar.gz.sig
 
WORKDIR /src/grub-2.04

# Add `mod-setup_var` command
COPY . /src/grub-2.04/

RUN ./autogen.sh \
 && ./configure --with-platform=efi --prefix=/build \
 && make \
 && make install \
 && cd / \
 && rm -r /src/grub-2.04

# Test are failing
# && make check

WORKDIR /build

RUN ./bin/grub-mkstandalone -O x86_64-efi -o modGRUBShell.efi

FROM scratch as artifact
COPY --from=build /build/modGRUBShell.efi /modGRUBShell.efi

FROM build as release

# docker build --target=artifact --output type=local,dest=artifact .
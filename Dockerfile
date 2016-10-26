FROM debian:wheezy
MAINTAINER Brian Lachance <blachance@gmail.com>

VOLUME /data
ARG INSTALL_SCRIPT=racket-6.6-x86_64-linux.sh
ARG DEST=/usr/local/racket

RUN apt-get update && \
    apt-get install -y sqlite3 ca-certificates openssl libglib2.0 libfontconfig \
    libcairo2 libpango1.0 libjpeg8

# ... Some tests in the Gregor benchmark require setting tz to America/New_York
RUN echo "America/New_York" > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata

COPY $INSTALL_SCRIPT .
RUN chmod +x $INSTALL_SCRIPT
RUN ./$INSTALL_SCRIPT --unix-style --dest $DEST --create-dir
ENV PATH=$PATH:$DEST/bin/

WORKDIR $DEST
RUN rm -r share/racket/pkgs/typed-racket
COPY typed-racket/ share/racket/pkgs/
COPY cast-no-check.patch .
RUN patch -i cast-no-check.patch share/racket/pkgs/typed-racket-lib/typed-racket/base-env/prims-contract.rkt
COPY contract-out-syntax-property.patch .
RUN patch -i contract-out-syntax-property.patch share/racket/collects/racket/contract/private/out.rkt
RUN raco setup --no-docs --no-install --no-launcher

WORKDIR extra-pkgs/gradual-typing-performance
COPY gradual-typing-performance .
COPY deps deps
RUN raco pkg install --deps fail --batch deps/* \
    tools/benchmark-util tools/benchmark-run tools/summarize

ENV NUMITERS=10
ENV DATADIR=/data
# TODO: need to make the -o argument to run.sh accept an absolute path
COPY run-experiments.sh .
CMD ["/bin/bash", "run-experiments.sh"]
FROM fpco/stack-build:lts-18.20 as build
RUN mkdir /opt/build
WORKDIR /opt/build

 # GHC dynamically links its compilation targets to lib gmp
RUN apt-get update \
  && apt-get download libgmp10
RUN mv libgmp*.deb libgmp.deb

COPY ./app /opt/build
RUN stack build --system-ghc
RUN mv "$(stack path --local-install-root --system-ghc)/bin" /opt/build/bin

# Base image for stack build so compiled artifact from previous
# stage should run
FROM ubuntu:22.04
RUN mkdir -p /opt/executable
WORKDIR /opt/executable

 # Install lib gmp
COPY --from=build /opt/build/libgmp.deb /tmp
RUN dpkg -i /tmp/libgmp.deb && rm /tmp/libgmp.deb

COPY --from=build /opt/build/bin .
CMD ["/opt/executable/app-exe"]

FROM google/cloud-sdk
VOLUME /build
RUN apt-get update && apt-get install -y -qq --no-install-recommends  xz-utils && apt-get clean
ADD build.sh /
RUN chmod +x /build.sh
ENTRYPOINT [ "/build.sh" ]

FROM nginx:1.15-alpine
STOPSIGNAL SIGTERM
EXPOSE 80
EXPOSE 443
USER 0

ADD image /root/image
RUN \
  find /root/image -type f -name '*.sh' -exec sed -i -e 's/\r//' {} \; && \
  cp -r /root/image/* / && \
  rm -rf /root/image

ENTRYPOINT ["/entrypoint/custom-entrypoint.sh"]

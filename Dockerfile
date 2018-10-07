FROM nginx:1.15-alpine
STOPSIGNAL SIGTERM
EXPOSE 80
EXPOSE 443
USER 0

ADD image /root/image
RUN \
  find /root/image -type f -regextype posix-extended -iregex '^.*\/((\.[A-Za-z0-9_\-\.]+)|([A-Za-z0-9_\-])|([A-Za-z0-9_\-]+[A-Za-z0-9_\-\.]\.(js|html|po|css|sh|conf|md|txt|json|py)))$' -exec sed -i -e 's/\r//' {} \; && \
  cp -r /root/image/* / && \
  rm -rf /root/image

ENTRYPOINT ["/entrypoint/custom-entrypoint.sh"]

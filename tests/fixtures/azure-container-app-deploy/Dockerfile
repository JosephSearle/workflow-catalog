# The Container Apps quickstart image, which serves / on port 80. BUILD_ID
# changes the image config, so each test run gets a new digest and the live
# test always makes a new revision.
FROM mcr.microsoft.com/k8se/quickstart@sha256:3a4d93c34c6753f24765ab17a36f1754aee9b02082b7d9553d17697b9e8252c4
ARG BUILD_ID=local
LABEL org.opencontainers.image.revision=$BUILD_ID

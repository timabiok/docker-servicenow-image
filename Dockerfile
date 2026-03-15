# Production Docker image for ServiceNow node (install.sh + runtime)
# Base: Amazon Linux 2 (matches script's yum usage)
FROM amazonlinux:2

# Install dependencies required by install.sh (no Java here; set JAVA_INSTALLER at runtime if needed)
RUN yum install -y -q --nogpgcheck \
    tar util-linux wget zip unzip gcc which vim curl nano zsh jq \
    glibc glibc.i686 libgcc rng-tools \
    awscli \
    && yum clean all

# Default Java for image; set JAVA_INSTALLER at runtime if using a different installer
ENV JAVA_INSTALLER=java-11-amazon-corretto-devel
RUN yum install -y -q "${JAVA_INSTALLER}" \
    && yum clean all

WORKDIR /app

# Copy install script and docker entrypoint
COPY install.sh /app/install.sh
COPY docker-entrypoint.sh /app/docker-entrypoint.sh

RUN chmod +x /app/install.sh /app/docker-entrypoint.sh

# Runtime env (override when running or in ECS task def)
# BUCKET, KEY, JSON_PORTS required; NODE_PORT=8443|9443 for which node to start
ENV NODE_PORT=8443
ENV JSON_PORTS="[8443,9443]"

ENTRYPOINT ["/app/docker-entrypoint.sh"]

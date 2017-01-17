FROM deeky666/base

MAINTAINER Steve Müller "deeky666@googlemail.com"

ARG POSTGRESQL_VERSION

# Download and install PostgreSQL server $POSTGRESQL_VERSION as lightweight package.
RUN \
    apt-get update -y && \
    apt-get install -y wget gcc-4.7 make libreadline-dev zlib1g-dev --no-install-recommends && \

    groupadd postgres && \
    useradd -r -g postgres -p postgres postgres && \

    mkdir -p /pgsql/srv /pgsql/log && \
    chown -R postgres:postgres /pgsql && \

    cd /tmp && \

    wget \
        -nv \
        --no-check-certificate \
        -O postgresql.tar.gz \
        https://ftp.postgresql.org/pub/source/v$POSTGRESQL_VERSION/postgresql-$POSTGRESQL_VERSION.tar.gz && \
    tar xf postgresql.tar.gz && \

    cd postgresql* && \

    ./configure \
        CC='gcc-4.7 -m64' \
        && \
    make -j`nproc` && \
    make install && \

    apt-get purge --auto-remove -y wget gcc-4.7 make libreadline-dev zlib1g-dev && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/local/pgsql/include

# Expose volumes for data and log files.
VOLUME ["/pgsql/log", "/pgsql/srv"]

# Initialize PostgreSQL data directory and define PostgreSQL server binary as entrypoint.
ENTRYPOINT /usr/local/pgsql/bin/initdb -D /pgsql/srv/ && echo "listen_addresses = '*'" >> /pgsql/srv/postgresql.conf && echo "fsync=off" >> /pgsql/srv/postgresql.conf && echo "full_page_writes=off" >> /pgsql/srv/postgresql.conf && echo "host all all 0.0.0.0/0 trust" > /pgsql/srv/pg_hba.conf && /usr/local/pgsql/bin/postmaster -D /pgsql/srv >/pgsql/log/postgresql.log 2>&1

USER postgres

# Expose PostgreSQL server port 5432.
EXPOSE 5432

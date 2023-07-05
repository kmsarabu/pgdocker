from ubuntu:18.04
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=US
ARG proj_version=7.1.0
ARG gdal_version=3.7.0
ARG geos_version=3.8.1
ARG postgis_version=3.0.2
ARG postgres_version=12.6
ARG pgpassword=postgres
ENV proj_version=${proj_version}
ENV gdal_version=${gdal_version}
ENV geos_version=${geos_version}
ENV postgis_version=${postgis_version}
ENV postgres_version=${postgres_version}
ENV pgpassword=${pgpassword}
ENV PGDATA /pgdata/db1

RUN apt-get update

RUN groupadd -f postgres && useradd -d /home/postgres -g postgres postgres && \
    usermod -aG sudo postgres

RUN apt-get -y install bash-completion wget \
 build-essential libssl-dev libffi-dev \
 python-dev cmake sqlite3 libsqlite3-0 libsqlite3-dev \
 libreadline-dev \
 zlib1g zlib1g-dev libkrb5-3 libkrb5-dev libpam-dev \
 libwbxml2-0 libwbxml2-dev libwbxml2-utils \
 xml2 libkf5ldap5 libkf5ldap-dev tcl-dev \
 libossp-uuid16 libossp-uuid-dev \
 libtcl8.6 libpg-perl perl libperl-dev \
 libxml2-dev libxml2 libcurl4-openssl-dev \
 libtiff5 libtiff5-dev libtiff-dev curl \
 build-essential zlib1g-dev flex bison libxml2-dev libxslt-dev libssl-dev libxml2-utils xsltproc

RUN wget https://github.com/json-c/json-c/archive/refs/tags/json-c-0.15-20200726.tar.gz && \
    tar -xvzf json-c-0.15-20200726.tar.gz && \
    cd json-c-json-c-0.15-20200726 && \
    mkdir json-c-build && \
    cd json-c-build && \
    cmake .. && make && make install && \
    cd ../.. && rm -rf json-c-0.15-20200726.tar.gz json-c-json-c-0.15-20200726

ENV PGBASE=/app/product
ENV PGHOME=$PGBASE/postgres/${postgres_version}
ENV PATH=$PATH:$PGHOME/bin

RUN mkdir -p $PGHOME /home/postgres/work && chown -hR postgres:postgres /app && \
    chown -hR postgres:postgres /home/postgres && \
    mkdir -p "$PGDATA" && chown -R postgres:postgres "$PGDATA" && chmod 777 "$PGDATA"

USER postgres
WORKDIR /home/postgres/work

RUN wget https://ftp.postgresql.org/pub/source/v${postgres_version}/postgresql-${postgres_version}.tar.gz && \
    tar -xvzf postgresql-${postgres_version}.tar.gz && \
    cd postgresql-${postgres_version}/ && \
    ./configure --prefix=$PGHOME --with-perl --with-tcl --with-gssapi --with-openssl --with-pam --with-ldap --with-ossp-uuid --with-libxml --with-libxslt && \
    make world  && \
    make install-world && \
    cd ..

RUN wget https://download.osgeo.org/proj/proj-${proj_version}.tar.gz && \
    tar -xvzf proj-${proj_version}.tar.gz && \
    cd proj-${proj_version} && \
    ./configure --prefix=$PGBASE/proj && \
    make && make install && \
    cd ..

RUN wget http://download.osgeo.org/geos/geos-${geos_version}.tar.bz2 && \
    bzip2 -d geos-${geos_version}.tar.bz2 && tar -xvf geos-${geos_version}.tar && \
    cd geos-${geos_version}/ && \
    ./configure --prefix=$PGBASE/geos && \
    make && make install && \
    cd ..

RUN wget https://github.com/OSGeo/gdal/releases/download/v${gdal_version}/gdal-${gdal_version}.tar.gz && \
    tar -xvzf gdal-${gdal_version}.tar.gz && \
    cd gdal-${gdal_version} && \
    ./configure --prefix=$PGBASE/gdal --with-proj=$PGBASE/proj && \
    make && make install && \
    cd ..

RUN wget http://download.osgeo.org/postgis/source/postgis-${postgis_version}.tar.gz && \
    tar -xvzf postgis-${postgis_version}.tar.gz && \
    cd postgis-${postgis_version} && \
    ./configure --with-geosconfig=$PGBASE/geos/bin/geos-config \
       --with-gdalconfig=$PGBASE/gdal/bin/gdal-config \
       --with-projdir=$PGBASE/proj \
       --without-protobuf \
       --with-pgconfig=$PGHOME/bin/pg_config && \
    make && make install


VOLUME /pgdata/db1


COPY docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

STOPSIGNAL SIGINT
EXPOSE 5432
WORKDIR /home/postgres
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$PGBASE/gdal/lib:$PGBASE/geos/lib:$PGBASE/proj/lib:/usr/local/lib

CMD ["postgres"]


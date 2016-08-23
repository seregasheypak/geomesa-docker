FROM cloudera/quickstart:5.7.0-0-beta

MAINTAINER Serega Sheypak <serega.sheypak@gmail.com>

RUN mkdir -p /tmp/geomesa-releases/geomesa-dist-1.2.5 \
    && curl -L http://repo.locationtech.org/content/repositories/geomesa-releases/org/locationtech/geomesa/geomesa-dist/1.2.5/geomesa-dist-1.2.5-bin.tar.gz \
    | tar -xvz -C /tmp/geomesa-releases/geomesa-dist-1.2.5

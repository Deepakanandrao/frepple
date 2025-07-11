#
# Copyright (C) 2023 by frePPLe bv
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

#
# STAGE 1: Compile and build the application
#

FROM ubuntu:24.04 AS builder

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

RUN apt-get -y -q update && \
  DEBIAN_FRONTEND=noninteractive apt-get -y install \
  cmake g++ git python3 python3-pip python3-dev python3-venv \
  psmisc libxerces-c3.2 libxerces-c-dev openssl libssl-dev \
  postgresql-client libpq5 libpq-dev locales && \
  rm -rf /var/lib/apt/lists/*

# An alternative to the copy is to clone from git:
# RUN git clone https://github.com/frepple/frepple.git frepple
COPY frepple-*.tar.gz ./

RUN src=`basename --suffix=.tar.gz frepple-*` && \
  tar -xzf *.tar.gz && \
  rm *.tar.gz && \
  cd $src && \
  cmake -B /build -DCMAKE_BUILD_TYPE=Release && \
  cmake --build /build --config Release --target package -- -j 2

FROM scratch AS package
COPY --from=builder /build/*.deb .

#
# STAGE 2: Build the deployment container
#

FROM ubuntu:24.04

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Download postgres clients (use when there are major postgresql releases which aren't in this ubuntu release)
RUN apt-get -y -q update && \
   DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends curl ca-certificates gnupg && \
   curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
   echo "deb http://apt.postgresql.org/pub/repos/apt/ noble-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
   apt-get -y -q update && \
   DEBIAN_FRONTEND=noninteractive apt-get -y install postgresql-client-17

COPY --from=builder /build/*.deb .

RUN apt-get -y -q update && \
  DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt install --no-install-recommends -f -y -q ./*.deb && \
  DEBIAN_FRONTEND=noninteractive apt -y install ca-certificates && \
  apt-get -y purge --autoremove && \
  apt-get clean && \
  rm -rf *.deb /var/lib/apt/lists/* /etc/apt/sources.list.d/pgdg.list && \
  # Run apache as the frepple user
  sed -i 's/export APACHE_RUN_USER=www-data/export APACHE_RUN_USER=frepple/' /etc/apache2/envvars && \
  sed -i 's/export APACHE_RUN_GROUP=www-data/export APACHE_RUN_GROUP=frepple/' /etc/apache2/envvars && \
  chown -R frepple:frepple /var/www/html /var/log/apache2 /var/run/apache2 && \
  chgrp -R frepple /etc/apache2 && \
  chmod -R g+w /var/www/html /var/log/apache2 /etc/apache2 /var/run/apache2 && \
  # Pipe the apache log files to the stdout of the container
  echo 'ErrorLog "|/usr/bin/tee ${APACHE_LOG_DIR}/error.log"' >> /etc/apache2/sites-available/z_frepple.conf && \
  echo 'CustomLog "|/usr/bin/tee ${APACHE_LOG_DIR}/access.log" "%v %h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\""\n' >> /etc/apache2/sites-available/z_frepple.conf && \
  a2dissite 000-default

EXPOSE 80

# Use the following lines to enable HTTPS.
# Inherit from this base image, add the following lines in your dockerfile
# and copy your certificate files into the image.
# RUN a2enmod ssl && \
#   a2ensite default-ssl && \
# EXPOSE 443

VOLUME ["/var/log/frepple", "/etc/frepple", "/var/log/apache2", "/etc/apache2"]

USER frepple

COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]

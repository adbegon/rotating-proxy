FROM quay.io/spivegin/gobetween:latest AS gobetween
FROM quay.io/spivegin/tlmbasedebian
MAINTAINER Matthias Kadenbach <matthias.kadenbach@gmail.com>
ENV DINIT=1.2.4 \
    DEBIAN_FRONTEND=noninteractive
ADD https://github.com/Yelp/dumb-init/releases/download/v1.2.4/dumb-init_${DINIT}_amd64.deb /tmp/dumb-init.deb

RUN apt-get update && apt upgrade -y &&\
    apt-get install -y apt-transport-https gnupg2 polipo haproxy ruby-full libssl-dev wget curl zlib1g-dev libyaml-dev libssl-dev && \
    ln -s /lib/x86_64-linux-gnu/libssl.so.1.0.0 /lib/libssl.so.1.0.0 &&\
    dpkg -i /tmp/dumb-init.deb &&\
    apt-get autoclean && apt-get autoremove &&\
    rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/* /root/*    

RUN mkdir /opt/bin && \
    echo deb https://deb.torproject.org/torproject.org stretch main >> /etc/apt/sources.list.d/tor.list &&\
    curl https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | gpg --import && \
    gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | apt-key add - &&\
    apt update &&\
    apt install -y tor deb.torproject.org-keyring &&\
    apt-get autoclean && apt-get autoremove &&\
    rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/* /root/*    

ADD --from=gobetween /opt/bin/gobetween /opt/bin/gobetween
RUN chmod +x /opt/bin/gobetween &&
    ln -s /opt/bin/gobetween /bin/gobetween
RUN update-rc.d -f tor remove
RUN update-rc.d -f polipo remove

RUN gem install excon -v 0.44.4

ADD start.rb /usr/local/bin/start.rb
RUN chmod +x /usr/local/bin/start.rb

ADD newnym.sh /usr/local/bin/newnym.sh
RUN chmod +x /usr/local/bin/newnym.sh

ADD haproxy.cfg.erb /usr/local/etc/haproxy.cfg.erb
ADD uncachable /etc/polipo/uncachable

EXPOSE 5566 4444

CMD /usr/local/bin/start.rb

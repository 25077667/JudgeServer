FROM ubuntu

COPY build/java_policy /etc
#RUN sed -E -i -e 's/(archive|ports).ubuntu.com/mirrors.aliyun.com/g' -e '/security.ubuntu.com/d' /etc/apt/sources.list
ENV DEBIAN_FRONTEND=noninteractive
RUN buildDeps='software-properties-common git libtool cmake python-dev libseccomp-dev curl' && \
    apt-get update && apt-get install -y python python3 python-pkg-resources python3-pkg-resources $buildDeps && \
    add-apt-repository universe && \
    add-apt-repository ppa:openjdk-r/ppa && add-apt-repository ppa:longsleep/golang-backports && \
    add-apt-repository ppa:ubuntu-toolchain-r/test && \
    add-apt-repository ppa:ondrej/php && \
    curl -fsSL https://deb.nodesource.com/setup_14.x | bash - && \
    apt-get update && apt-get install -y golang-go openjdk-11-jdk php-cli nodejs gcc-9 g++-9 python3-pip && \
    update-alternatives --install  /usr/bin/gcc gcc /usr/bin/gcc-9 40 && \
    update-alternatives --install  /usr/bin/g++ g++ /usr/bin/g++-9 40 && \
    phpJitOption='opcache.enable=1\nopcache.enable_cli=1\nopcache.jit=1205\nopcache.jit_buffer_size=64M' && \
    echo $phpJitOption > /etc/php/8.0/cli/conf.d/10-opcache-jit.ini && \
    pip3 install -i https://mirrors.aliyun.com/pypi/simple/ -I --no-cache-dir psutil gunicorn flask requests idna && \
    cd /tmp && git clone -b main --depth 1 https://github.com/25077667/Judger.git && cd Judger && \
    mkdir build && cd build && cmake .. && make && make install && cd ../bindings/Python && python3 setup.py install && \
    apt-get purge -y --auto-remove $buildDeps && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    mkdir -p /code && \
    useradd -u 12001 compiler && useradd -u 12002 code && useradd -u 12003 spj && usermod -a -G code spj
HEALTHCHECK --interval=5s --retries=3 CMD python3 /code/service.py
ADD server /code
WORKDIR /code
RUN gcc -shared -fPIC -o unbuffer.so unbuffer.c
ENV PORT=8081
ENTRYPOINT /code/entrypoint.sh

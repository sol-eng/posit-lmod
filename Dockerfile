FROM ubuntu:noble

ARG PYTHON_VERSION="3.11.9"

RUN apt-get update && apt-get install -y curl gdebi-core 

RUN curl -O https://cdn.rstudio.com/python/ubuntu-2404/pkgs/python-${PYTHON_VERSION}_1_amd64.deb && \
    apt install -y ./python-${PYTHON_VERSION}_1_amd64.deb && rm -f python*.deb

RUN /opt/python/${PYTHON_VERSION}/bin/pip install --upgrade \
    pip setuptools wheel && rm -rf /root/.cache


RUN echo "export PATH=/opt/python/${PYTHON_VERSION}/bin:\$PATH" > /etc/profile.d/path.sh

RUN apt-get install -y lmod gcc g++ make file git zip bzip2 xz-utils patch libfindbin-libs-perl 

RUN useradd -s /bin/bash -m eb 

RUN mkdir /apps 

RUN chown eb /apps

USER eb

RUN bash -l -c "pip install easybuild==4.9.4"

#braindump to remember how - if needed - individual EB recipes could be built step-by-step
#eb -D -r . R-bundle-Bioconductor-3.19-gfbf-2023b-R-4.4.1.eb R-bundle-Bioconductor-3.18-gfbf-2023b-R-4.3.3.eb > log 
#while read line ; do IFS="/" read -ra parts <<< "$line"; ebfile=`echo ${parts[-2]} | cut -d " " -f 1`; echo "bash -l -c \"eb --prefix /apps -r . $ebfile\"; done < log

COPY eb/*.eb /home/eb/

WORKDIR /home/eb
# BLIS does not work well with generic optarch, hence set it explicitly

RUN sed -i 's/ auto/ generic/' ~/.local/easybuild/easyconfigs/b/BLIS/BLIS-0.9.0-GCC-13.2.0.eb 

RUN bash -l -c "eb --download-timeout=120 --optarch=GENERIC --skip-test-step --prefix /apps -r . R-4.4.1-gfbf-2023b.eb"
RUN bash -l -c "eb --download-timeout=120 --optarch=GENERIC --skip-test-step --prefix /apps -r . R-4.3.3-gfbf-2023b.eb"

RUN bash -l -c "eb --download-timeout=120 --optarch=GENERIC --skip-test-step --prefix /apps -r . R-bundle-CRAN-2024.06-gfbf-2023b-R-4.4.1.eb"

#RUN bash -l -c "eb --download-timeout=120 --optarch=GENERIC --skip-test-step --prefix /apps -r . arrow-R-14.0.1-gfbf-2023b-R-4.4.1.eb"

#RUN bash -l -c "eb --download-timeout=120 --optarch=GENERIC --skip-test-step --prefix /apps -r . R-bundle-Bioconductor-3.19-gfbf-2023b-R-4.4.1.eb"


USER root

ARG PWB_VERSION="2024.12.0-467.pro1"

RUN curl -LO https://s3.amazonaws.com/rstudio-ide-build/server/jammy/amd64/rstudio-workbench-${PWB_VERSION}-amd64.deb && gdebi -n ./rstudio-workbench-${PWB_VERSION}-amd64.deb && rm -f rstudio-workbench-${PWB_VERSION}-amd64.deb

RUN rm -f /etc/launcher/launcher.{pem,pub}
RUN echo "modules-bin-path=/etc/profile.d/lmod.sh" >> /etc/rstudio/rserver.conf
RUN echo "r-versions-scan=0" >> /etc/rstudio/rserver.conf

#RUN echo "Module: R-bundle-Bioconductor/3.19-gfbf-2023b-R-4.4.1\nLabel: R 4.4.1 with Bioconductor 3.19" > /etc/rstudio/r-versions
#RUN echo "\n\n" >> /etc/rstudio/r-versions
RUN echo "Module: R-bundle-CRAN/2024.06-gfbf-2023b-R-4.4.1\nLabel: R 4.4.1 with CRAN only" >> /etc/rstudio/r-versions
RUN echo "\n\n" >> /etc/rstudio/r-versions
RUN echo "Module: R/4.4.1-gfbf-2023b\nLabel: R 4.4.1 with base/rec only" >> /etc/rstudio/r-versions
RUN echo "\n\n" >> /etc/rstudio/r-versions
RUN echo "Module: R/4.3.3-gfbf-2023b\nLabel: R 4.3.3 with base/rec only" >> /etc/rstudio/r-versions
RUN echo "\n\n" >> /etc/rstudio/r-versions

ARG PCT_VERSION="2024.11.0"

RUN curl -O https://cdn.posit.co/connect/${PCT_VERSION%.*}/rstudio-connect_${PCT_VERSION}~ubuntu24_amd64.deb &&  apt install -y ./rstudio-connect_${PCT_VERSION}~ubuntu24_amd64.deb && rm -f ./rstudio-connect_${PCT_VERSION}~ubuntu24_amd64.deb

COPY config/rstudio-connect.gcfg /etc/rstudio-connect

RUN mkdir -p /apps/wrappers/bin

COPY scripts/* /apps/wrappers/bin/

RUN chmod +x /apps/wrappers/bin/*

RUN useradd -s /bin/bash -m rstudio

RUN echo "/apps/modules/all" >> /etc/lmod/modulespath

ENTRYPOINT [ "/apps/wrappers/bin/start.sh" ]


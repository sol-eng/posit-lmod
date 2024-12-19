#!/bin/bash

rm -f /etc/launcher.{pub,pem}

cat << EOF > /etc/rstudio/r-versions
Module: R-bundle-CRAN/2024.06-gfbf-2023b-R-4.4.1
Label: R 4.4.1 with CRAN only

Module: R/4.4.1-gfbf-2023b
Label: R 4.4.1 with base/rec only

Module: R/4.3.3-gfbf-2023b
Label: R 4.3.3 with base/rec only
EOF
/usr/lib/rstudio-server/bin/license-manager activate $PWB_LICENSE

configdir="/etc/rstudio"

rm -f /etc/rstudio/launcher.{pem,pub}
openssl genpkey -algorithm RSA \
            -out $configdir/launcher.pem \
            -pkeyopt rsa_keygen_bits:2048 && \
    chown rstudio-server:rstudio-server \
            $configdir/launcher.pem && \
    chmod 0600 $configdir/launcher.pem

openssl rsa -in $configdir/launcher.pem \
            -pubout > $configdir/launcher.pub && \
    chown rstudio-server:rstudio-server \
            $configdir/launcher.pub

rstudio-launcher start
rstudio-server start

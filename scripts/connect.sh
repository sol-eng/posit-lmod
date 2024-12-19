#!/bin/bash

/opt/rstudio-connect/bin/license-manager activate $PCT_LICENSE
/opt/rstudio-connect/bin/connect --config /etc/rstudio-connect/rstudio-connect.gcfg

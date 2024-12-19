#!/bin/bash

source /etc/profile.d/lmod.sh 
ml purge 
ml use /apps/modules/all
ml load R-bundle-CRAN/2024.06-gfbf-2023b-R-4.4.1

exec R "$@"

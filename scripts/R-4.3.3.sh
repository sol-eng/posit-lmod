#!/bin/bash

source /etc/profile.d/lmod.sh 
ml use /apps/modules/all
ml purge
ml load R/4.3.3-gfbf-2023b 

exec R "$@"

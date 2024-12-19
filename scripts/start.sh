#!/bin/bash

/apps/wrappers/bin/user.sh
/apps/wrappers/bin/connect.sh &
/apps/wrappers/bin/workbench.sh & 
wait

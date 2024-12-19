<<<<<<< HEAD
# posit-lmod
=======
# connect-lmod
>>>>>>> fa9341e (first commit)

This repository provides a test environment showcasing how to best/better integrate environment modules into Posit Connect. It also deploys Posit Workbench but uses the default mechanism to deal with [environment modules](https://docs.posit.co/ide/server-pro/r/using_multiple_versions_of_r.html#modules) there. 

For Posit Connect, so far the default "integration" of environment modules was to use [program supervisors](https://docs.posit.co/connect/admin/process-management/index.html#program-supervisors). The supervisor approach recently showed a number of issues such as supervisors not active during certain stages of the lifecycle of an app and as a consequence many environment variables missing. In a recent interaction with a customer it became apparent that the use of supervisors with environment modules in particular is fraught with many issues. 

While working on a demo environment to show all of those problems (it is not as straightforward as it sounds to just build a couple of R versions using environment modules in a separate application stack), a new solution was found that could nicely complement the program supervisors. Instead of using the program supervisors to load the appropriate environment modules so that the selected R version will start properly, we are using individual wrapper scripts for each R version that is activating environment modules and then loads the respective R module before running `exec R "$@"`. 

An example of such a wrapper script (e.g. `/apps/wrappers/bin/R-4.4.1.sh`) is 

```
#!/bin/bash

source /etc/profile.d/lmod.sh 
ml purge 
ml use /apps/modules/all
ml load R-bundle-CRAN/2024.06-gfbf-2023b-R-4.4.1

exec R "$@"
```

Within the Posit Connect configuration this now can be use in the `[R]` section of `rstudio-connect.gcfg`

```
[R]
ExecutableScanning = false
EnvironmentManagement = false
Executable = /apps/wrappers/bin/R-4.4.1.sh
```

In Posit Workbench the same R version would be configured via the following two entries

* Add `modules-bin-path=/etc/profile.d/lmod.sh` and `r-versions-scan=0` to `/etc/rstudio/rserver.conf`
* Add the below lines to `/etc/rstudio/r-versions`
```
Module: R-bundle-CRAN/2024.06-gfbf-2023b-R-4.4.1
Label: R 4.4.1 with CRAN bundle
```

Such a setup has been built into a docker container (cf. Dockerfile) 

## How to use the environment

### Initial setup 

First, you will need to set the following mandatory environment variables: 
* `PWB_LICENSE`, `PCT_LICENSE` point to the license key for Posit Workbench and Connect, respectively
* `RSTUDIO_PW` should point to a string that will server as the password for the `rstudio` account. Important: Do ***not*** use `rstudio` as password if working non-locally !

Then you simply can run 
```
docker pull mmayer123/posit-lmod
docker-compose up -d 
```

and after a while you will have a docker environment up and running that exposes Posit Workbench on port 8787 and Posit Connect on port 3939.

Please note that the container 
* is 9 GB in size
* will not work on a an M1/2/3/4 powered Mac, not even with Rosetta 2 and AppleV support. 

### Working with the environment

You now can log into Posit Workbench, launch an RStudio Pro session and see that there is 3 editions of R available 
* R 4.4.1 with base/rec only: Only base and recommended packages available
* R 4.3.3 with base/rec only: Same as above, just for 4.3.3
* R 4.4.1 with CRAN only: R 4.4.1 with a large number of contributed packages, preinstalled in an application bundle

Once you selected an R version to work with, you can create a sample shiny app (e.g. Old Faithful Geyser), run it locally without any additional package installation and then publish it to Connect. Because Posit connect uses the same R installation and has `EnvironmentManagement` set to `False`, deployment is super fast as Connect will simply use the preinstalled packages. 


## Questions:

The above setup works very well for an environment, where only preinstalled packages (same packages and versions on Workbench as well as on Connect) are used (this is the case with many qualified environments in Pharma/LSH, for example). 

* Is there any way to instead setting `EnvironmentManagement` to `False` allow for a bit more lax environment management where Connect automatically figures out if a package is missing and only then installs this package for the respective app ? (IIRC this is called a "slushy" environemnt for some).
* What can be done if a user on Workbench updates a certain pre-installed package and publishes an app using this new version to Connect ? Can Connect be configured to detect this ? (i.e. only selectively installing the newer version but still retaining the old version ?


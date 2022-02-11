---
layout: single
title: "GreatMod - How to install"
permalink: /HowInstall/
toc: true
toc_label: "Requirements"
toc_icon: "cog"
---

## Docker

You need to have docker installed on your machine, for more info see this document:
https://docs.docker.com/engine/installation/.

Ensure your user has the rights to run docker (witout the use of ```sudo```). To create the docker group and add your user:

* Create the docker group.

```
  $ sudo groupadd docker
```
* Add your user to the docker group.

```
  $ sudo usermod -aG docker $USER
```
* Log out and log back in so that your group membership is re-evaluated.


## GreatSPN
The installation of the workflow requires the downloading of the extended version of the [*GreatSPN* editor](http://www.di.unito.it/~amparore/mc4cslta/editor.html).

### macOS installation instructions

GreatSPN compiles and runs successfully on macOS. 

1. Install [*HomeBrew*](https://brew.sh/)
2. Install *openjdk* by using the following terminal command lines:
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install openjdk
```
3. Open the *.bash_profile* and add the following two paths:
```
export PATH=/usr/local/opt/openjdk/bin/:$PATH #il path in cui è stato installato openjdk
alias GreatSPN='java -jar /Users/xxx/Documents/GreatSPN/Editor.jar’ 
```
4. Open GreatSPN by using the terminal command line: 
```
greatspn_editor
```

## EPIMOD
To install **EPIMOD** you can use use **devtools**:

```
install.packages("devtools")
library(devtools)
install_github("https://github.com/qBioTurin/epimod", ref="master")
```

**Download Containers**:

To download all the docker images exploited by **EPIMOD**  you can use:

```
library(epimod)
downloadContainers()
```


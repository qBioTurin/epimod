# epimod
A modeling framework  for the analysis of epidemiological systems, which exploits Petri Net graphical formalism, R environment, and Docker containerization to derive a tool easily accessible  by any researcher even without advanced mathematical and computational skills.


### Install
To install **epimod** you can use use **devtools**:

```
install.packages("devtools")
library(devtools)
install_github("https://github.com/qBioTurin/epimod", ref="master")
```

#### Download Containers
To download all the docker images exploited by **epimod**  you can use:

```
library(epimod)
downloadContainers()
```


### Requirements
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



### Disclaimer:
**epimod**  developers have no liability for any use of **epimod**  functions, including without limitation, any loss of data, incorrect results, or any costs, liabilities, or damages that result from use of **epimod** .

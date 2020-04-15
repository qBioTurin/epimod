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


### Repository
The following list is a selection of project developed with **epimod**, providing both the necessary files and explainations to perform the anlaysis. If you find any issue while running projecte listed here, please contact the person or group responsible for such project and not **epimod** developers team. If you are interested in sharing your project, prepare a git repository following the instruction [here](missing.page)

* [Lotka-Volterra](https://github.com/qBioTurin/Lotka-Volterra): The Lotka–Volterra equations, also known as the predator–prey equations, are a pair of first-order nonlinear differential equations, frequently used to describe the dynamics of biological systems in which two species interact, one as a predator and the other as prey([more information..](https://en.wikipedia.org/wiki/Lotka%E2%80%93Volterra_equations)). This simple model is presented as an introduction to the *epimod* usage, showing step by step *epimod*'s base functionalities. 
* [SIR](https://github.com/qBioTurin/SIR): The SIR model is one of the simplest compartmental models, and many models are derivatives of this basic form. The model consists of three compartments: S for the number of susceptible, I for the number of infectious, and R for the number of recovered or deceased (or immune) individuals. This simple model is presented as an introduction to the *epimod* usage, showing step by step both base and advanced *epimod*'s functionalities.
* [Pertussis](https://github.com/qBioTurin/Pertussis):
* [COVID-19](https://github.com/qBioTurin/COVID-19): 


### Disclaimer
**epimod**  developers have no liability for any use of **epimod**  functions, including without limitation, any loss of data, incorrect results, or any costs, liabilities, or damages that result from use of **epimod** .

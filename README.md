# epimod
A modeling framework for the analysis of epidemiological systems, which exploits Petri Net graphical formalism, R environment, and Docker containerization to derive a tool easily accessible by any researcher even without advanced mathematical and computational skills.


### Install
To install **epimod** you can use use **devtools**:

```
install.packages("devtools")
library(devtools)
install_github("https://github.com/qBioTurin/epimod", ref="master")
```

#### Download Containers
To download all the docker images exploited by **epimod** you can use:

```
library(epimod)
downloadContainers()
```


### Requirements
You need to have docker installed on your machine, for more info see this document:
https://docs.docker.com/engine/installation/.

Ensure your user has the rights to run docker (without the use of ```sudo```). To create the docker group and add your user:

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
The following list is a selection of project developed with **epimod**, providing both the necessary files and explanations to perform the analysis. If you find any issue while running project listed here, please contact the person or group responsible for such project and not **epimod** developers team. If you are interested in sharing your project, prepare a git repository following the instruction [here](missing.page).

**Step-by-step applications**
* [SIR](https://github.com/qBioTurin/SIR): The SIR model is one of the simplest compartmental models, and many models are derivatives of this basic form. The model consists of three compartments: S for the number of susceptible, I for the number of infectious, and R for the number of recovered or deceased (or immune) individuals ([more information](https://en.wikipedia.org/wiki/Compartmental_models_in_epidemiology)). This simple model is presented as an introduction to the *epimod* usage, showing step by step both base and advanced *epimod*'s functionalities.
* [Lotka-Volterra](https://github.com/qBioTurin/Lotka-Volterra): The Lotka–Volterra equations, also known as the predator–prey equations, are a pair of first-order nonlinear differential equations, frequently used to describe the dynamics of biological systems in which two species interact, one as a predator and the other as prey ([more information](https://en.wikipedia.org/wiki/Lotka%E2%80%93Volterra_equations)). This simple model is presented as an introduction to the *epimod* usage, showing step by step *epimod*'s base functionalities. 

**Complex applications**
* [Pertussis](https://github.com/qBioTurin/Pertussis): The pertussis model has been developed by the University of Turin in a joint work with [Adres](http://www.adreshe.com/) and [ISI Foundation](https://www.isi.it/en/home). The model allows to study the evolution of the Pertussis through several decades, starting from mid 70's, and the effects of the governmental vaccination policies. 
* [COVID-19](https://github.com/qBioTurin/COVID-19): The coronavirus disease 19 (COVID-19) is viral infection highly transmittable caused by severe acute respiratory syndrome coronavirus 2 (SARS-CoV-2). In February 21<sup>st</sup>, 2020 the first person-to-person transmission of SARS-CoV-2 was reported in Italy. Afterwards, the number of people infected with COVID-19 increased rapidly, firstly in northern Italian regions and then it rapidly expands in all Italian territories. The model available here has been developed by the University of Turin and has been successfully employed to study the pathogen diffusion in the Piedmont region.  
* [Multiple Slerosis](https://github.com/qBioTurin/Multiple-Sclerosis): Multiple Sclerosis is a chronic and potentially highly disabling disease with considerable social impacts and economic consequences. We exploited the main features characterizing **epimod** to calibrate the  model parameters, and to reproduce the typical oscillatory behavior relating to the onset of the disease by supposing a breakdown of the cross-balance regulation mechanisms at the peripheral level and studying different scenarios.
* [West Nile Virus](https://github.com/qBioTurin/WestNileVirus): the West Nile Virus (WNV) disease is one of the most recent emerging mosquito-borne diseases in Europe and North America, it is transmitted to birds through the bite of an infected mosquito and mosquitoes become infected by biting infected birds. **Epimod** is currently being used to study WNV diffusion, again in the Piedmont region, within the CRT (Cassa di Risparmio di Torino) funded project ”Creation of a computational framework to model and study West Nile Fever” (Cod. ROL: 67410).


### Disclaimer
**epimod**  developers have no liability for any use of **epimod**  functions, including without limitation, any loss of data, incorrect results, or any costs, liabilities, or damages that result from use of **epimod**.

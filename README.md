# epimod
A modeling framework for the analysis of epidemiological systems, which exploits Petri Net graphical formalism, R environment, and Docker containerization to derive a tool easily accessible by any researcher even without advanced mathematical and computational skills.


### Install
To install **epimod** you can use use **devtools**:

```
install.packages("devtools")
library(devtools)
install_github("https://github.com/qBioTurin/epimod", ref="epimod_pFBA")
```

#### Download Containers
To download all the docker images exploited by **epimod** you can use:

```
library(epimod)
downloadContainers()
```

---

### Building Docker Images

The script `inst/Docker/build_images.sh` builds and pushes all (or selected) epimod Docker images as multi-platform manifests (`linux/amd64` and `linux/arm64`) to Docker Hub.

**Prerequisites**
- Docker with [buildx](https://docs.docker.com/buildx/working-with-buildx/) support
- Logged in to Docker Hub (`docker login`)

**Usage**

```bash
cd inst/Docker

# Build and push all images (Analysis, Calibration, Generation, Sensitivity, Display)
./build_images.sh <TAGNAME>

# Build and push a single image
./build_images.sh <TAGNAME> Display

# Build and push a single image with a custom branch label
./build_images.sh <TAGNAME> Analysis epimod_pFBA
```

The `Display` image is built from `inst/Containers/Display/` and requires its `shinyApp/` subfolder to contain the app files (`server.R`, `ui.R`, `R/`, `www/`).

> **Note:** The `Generation` and `Display` images only target `linux/amd64` — Generation due to its custom multi-stage build, Display because `rocker/shiny` does not provide an `arm64` variant.

---

### Visualising Results with `display_data()`

The `display_data()` function launches the **EpiMod Plot Viewer** Shiny app inside a Docker container, allowing interactive exploration of simulation outputs (Analysis, Sensitivity, Calibration).

**Start the viewer**

```r
library(epimod)

# Mount a local results folder (accessible via the "Local" tab)
display_data(volume = "/path/to/your/results", port = 3838)

# Start without a pre-mounted folder (use the "Cloud (ZIP)" tab to upload results)
display_data(port = 3838)
```

The app will be available at **http://localhost:3838/display**.

If a container is already running on the selected port it is automatically stopped and replaced.

**Stop the viewer**

```r
stop_display()
```

**Parameters**

| Parameter | Default | Description |
|-----------|---------|-------------|
| `volume`  | `NULL`  | Host folder mounted as the data directory inside the container. When provided, the "Local" tab is pre-populated with this path. |
| `port`    | `3838`  | Host port the Shiny app listens on. |

**Supported experiment types**

| Type | Description |
|------|-------------|
| Analysis | Time-series traces from `model.analysis()` |
| Sensitivity | PRCC / Sobol plots from `model.sensitivity()` |
| Calibration | Best-fit traces from `model.calibration()` |

---



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

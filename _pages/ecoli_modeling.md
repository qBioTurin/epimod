---
title: "E. coli Metabolic Modeling"
layout: single
permalink: /ecoli_modeling/
author_profile: true
header:
  overlay_color: "#000"
  overlay_filter: "0.5"
  overlay_image: /assets/images/FBA/Cdifficile/Schema.png
toc: true
toc_label: "Index"
toc_icon: "cog"
---

# Using UnifiedGreatMod to integrate transcriptional data onto *Escherichia coli* genome-scale metabolic model (iML1515) growing on different regimes of carbon feeding

## Overview

This example demonstrates GreatMod's capability to integrate **Flux Balance Analysis (FBA)** with **Petri Net dynamical models** to simulate multi-state metabolic systems. The framework mechanistically simulates the metabolic output of *E. coli* growing under various transcriptional programs and environmental nutrient perturbations.

## Petri Net-based model of *E. coli* strain K-12

### Background

**Epimod** is an analysis tool that integrates Flux Balance Analysis (FBA) and Petri Net dynamical models based on Ordinary Differential Equations (ODEs) into a general and unified modeling framework. This repository contains a working example introducing the framework's ability to simulate multi-state systems. The FBA optimization problem is solved along with constraints on the rate of change of metabolite levels at specific time instants.

We have shown that Epimod can mechanistically simulate the metabolic output of *E. coli* growing under various transcriptional programs and environmental nutrient perturbations. Therefore, Epimod provides a framework for analyzing the transience of metabolism due to metabolic reprogramming and obtaining insights for the design of metabolic networks.

### Methods

FBA has become an established constraint-based method approach to studying metabolic networks. However, mechanism-based modeling approaches are the best option to model biological systems with finer-grained detail-up perturbations. Indeed, systems of ODEs can not only account for the steady-state analysis of the metabolic network but even the dynamics of medium culture metabolites concentration over time given an initial state.

The so-implemented time-dependent analysis depends on an input metabolic network. At each time, the values of external metabolite concentrations are updated by solving ODEs and values are then translated into constraints for FBA. In turn, FBA solutions are recycled as kinetic parameters for the ODEs. In doing so, the flow of metabolites through the *E. coli* metabolic network was calculated given specific media enriched with various carbon regimes supporting growth.

Simulations were performed using the genome-scale metabolic COBRA model of *E. coli* K-12 strain MG1655 while the inclusion of a specific environment is achieved by tuning constraints of the target metabolic model's boundary reactions.

### Results

The model can readily identify different metabolic behaviors depending on environmental and transcriptional status, providing the translation of quantitative values into discrete intervals and allowing flux analyses. It is important to note that FBA makes several assumptions, e.g., steady-state metabolite concentrations (meaning there is no change in metabolite concentrations over time).

Our results point to the steady-state constraint parametrization of fluxes as a determinant of model inaccuracy. To overcome these limitations, expanding the Petri Net model to represent other medium constituents could be a promising route toward more accurate models of metabolic physiology.

## Carbon Source Feeding Scenarios

The following carbon source supplementation scenarios for a fed-batch were simulated:

- **Constant feeding**: The feed rate of glucose and lactose is constant throughout the culture.
- **Linear feeding**: The feed rate of glucose and lactose are increased linearly over time to match the growth rate of the cells.
- **Pulsed feeding (60s)**: Glucose and lactose are added in repeated cycles of short duration, followed by a period of no feeding; the same total amount of glucose was fed in repeated 300s (5 min) cycles for 60s.
- **Pulsed feeding (150s)**: Glucose and lactose are added in repeated cycles of short duration, followed by a period of no feeding; the same total amount of glucose was fed in repeated 300s (5 min) cycles for 150s.
- **Blank**: The culture does not have glucose and lactose added to it.

## Gene Expression Integration

Gene expression data integration allows the metabolic model to reflect not just the internal state of the cell but also the external environment in which the cell is growing. Expression data was obtained from *E. coli* growing in a glucose-enriched minimal medium through the commercial microarray platform Affymetrix GeneChip system.

The dataset is available in the GEO database under the identifier **GSE2037**, which includes samples collected during the mid-log phase from cells exposed to various carbon sources (glucose, glycerol, succinate, L-alanine, acetate, and L-proline).

## Model Metrics

The *E. coli* str. K-12 substr. metabolic model (iML1515) downloaded from BiGG Models has the following metrics:

- **Metabolites**: 1877
- **Reactions**: 2712
- **Genes**: 1516

## Repository

All code, models, and simulation files are available on GitHub:

**[qBioTurin/Ec_coli_modelling](https://github.com/qBioTurin/Ec_coli_modelling)**

The repository includes:
- Petri Net model files
- Metabolic model files (iML1515)
- Parameter files for different carbon feeding regimes
- R scripts for simulation and analysis
- Results and visualization plots

## Timing Performance

Simulation execution times (CPU: Intel i7-3520M @ 3.600GHz):
- **Compiling phase**: ~10 minutes
- **Analysis phase**: ~5 minutes

---

*For more details on the methodology and results, please visit the [GitHub repository](https://github.com/qBioTurin/Ec_coli_modelling).*

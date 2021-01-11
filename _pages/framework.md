---
layout: single
title: "GreatMod - Framework"
permalink: /framework/
--- 

# Introduction
**GreatMod** represents a new way of facing the modeling analysis, exploiting the high-level graphical formalism, called Petri Net (PN), and its generalizations, which provide a compact, parametric and intuitive graphical description of the system and automatically derivation of the low-level mathematical processes (either deterministic and stochastic) characterizing the system dynamics.
The framework strengths can be summarized into four points:

1. the use of a graphical formalism to simplify  the model creation phase exploiting the *GreatSPN* GUI; 
2. the implementation of an R package, **EPIMOD**, providing  a friendly interface  to access the analysis techniques (from the sensitivity analysis and calibration of the parameters to the model simulation); 
3. a high level of portability and reproducibility granted by  the containerization of all analysis techniques implemented in the framework; 
4. a well-defined schema and related infrastructure to allow users to easily integrate their own analysis workflow in the framework.

The following image shows the framework schema depicting its modules and its functionalities from a user point of view.

![](/assets/images/Framework.png)
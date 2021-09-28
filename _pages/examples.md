---
title: "GreatMod - Applications"
permalink: /examples/
layout: splash
intro: 
  - excerpt: ''
feature_rowEasy:
  - image_path: /assets/images/SIR.png
    alt: "placeholder image 2"
    title: "SIR"
    excerpt: "The SIR model is one of the simplest compartmental models, and many models are derivatives of this basic form. The model consists of three compartments: S for the number of susceptible, I for the number of infectious, and R for the number of recovered or deceased."
    url: "/sir/"
    btn_label: "Read More"
    btn_class: "btn--primary"  
  - image_path: /assets/images/lotkaV.png
    alt: "placeholder image 2"
    title: "Lotka Volterra"
    excerpt: "The Lotka–Volterra equations, also known as the predator–prey equations, are a pair of first-order nonlinear differential equations, frequently used to describe the dynamics of biological systems in which two species interact, one as a predator and the other as prey. "
    url: "/Lotka/"
    btn_label: "Read More"
    btn_class: "btn--primary"  
feature_rowComplex:
  - image_path: /assets/images/COVID/COVIDmodel.png
    alt: "placeholder image 2"
    title: "COVID-19"
    excerpt: "Investigation of the COVID-19 diffusion in the Piedmonnt region"
    url: "/covid19/"
    btn_label: "Read More"
    btn_class: "btn--primary"  
  - image_path: /assets/images/Pertussis/PertussisModel.png
    alt: "placeholder image 2"
    title: "Pertussis"
    excerpt: "Investigation of the pertussis epidemiology in Italy"
    url: "/Pertussis/"
    btn_label: "Read More"
    btn_class: "btn--primary"  
  - image_path: /assets/images/MS/MSmodel.jpg
    alt: "placeholder image 2"
    title: "Multiple Sclerosis"
    excerpt: "Analysis of the immune response in Multiple Sclerosis given specific treatments"
    url: "/ms/"
    btn_label: "Read More"
    btn_class: "btn--primary"  
---

{% include feature_row id="intro" type="center" %}


##   Step-by-step Applications
These simple models are presented as an introduction to the **GreatMod** usage, showing step by step the base functionalities of the R package, *epimod*.

{% include feature_row id="feature_rowEasy" %}

##  Complex Applications
{% include feature_row id="feature_rowComplex" %}

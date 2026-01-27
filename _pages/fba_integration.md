---
title: "Flux Balance Analysis Integration"
permalink: /fba_integration/
layout: splash
header:
  overlay_color: "#000"
  overlay_filter: "0.5"
  overlay_image: /assets/images/FBA/Cdifficile/Schema.png
intro: 
  - excerpt: 'GreatMod seamlessly integrates **Flux Balance Analysis (FBA)** with dynamic Petri Net models to enable **multi-scale modeling** of biological systems. This powerful combination allows researchers to couple genome-scale metabolic networks with population-level dynamics.'
feature_row_examples:
  - image_path: /assets/images/FBA/Cdifficile/Schema.png
    alt: "C. difficile Model"
    title: "Host-Pathogen Dynamics: C. difficile Infection"
    excerpt: "Study of metabolic reprogramming during *Clostridium difficile* infection, including the acquisition of antibiotic-resistant phenotypes through heme supplementation."
    url: "/Cdifficile/"
    btn_label: "View Example"
    btn_class: "btn--primary"
  - image_path: /assets/images/Framework.png
    alt: "E. coli metabolic modeling"
    title: "E. coli Metabolic Modeling"
    excerpt: "Integration of transcriptional data onto *Escherichia coli* genome-scale metabolic model (iML1515) growing on different regimes of carbon feeding."
    url: "/ecoli_modeling/"
    btn_label: "View Example"
    btn_class: "btn--primary"
---

{% include feature_row id="intro" type="center" %}

## What is FBA Integration?

The integration of **Flux Balance Analysis (FBA)** with Petri Net models creates a powerful multi-scale framework that bridges:
- **Genome-scale metabolic networks** (constraint-based modeling via FBA)
- **Dynamic system behavior** (ODEs and stochastic simulations via Petri Nets)

This approach allows you to:
- Model metabolic reprogramming in response to environmental changes
- Analyze host-pathogen metabolic interactions
- Predict phenotypic behavior under different nutritional conditions
- Couple intracellular metabolism with population dynamics

---

## Examples

<style>
.fba-cards {
  display: flex;
  gap: 2rem;
  margin: 2rem 0;
  flex-wrap: wrap;
  justify-content: center;
}
.fba-card {
  flex: 1;
  min-width: 300px;
  max-width: 450px;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  transition: transform 0.2s, box-shadow 0.2s;
  background: white;
}
.fba-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 4px 16px rgba(0,0,0,0.15);
}
.fba-card h3 {
  margin: 0;
  padding: 1.5rem;
  background: #f8f9fa;
  font-size: 1.2rem;
  text-align: center;
  border-bottom: 2px solid #e0e0e0;
}
.fba-card img {
  width: 100%;
  height: 200px;
  object-fit: cover;
  display: block;
}
.fba-card-content {
  padding: 1.5rem;
}
.fba-card-content p {
  margin-bottom: 1.5rem;
  line-height: 1.6;
}
.fba-card .btn {
  display: inline-block;
  padding: 0.6rem 1.5rem;
  background: #52adc8;
  color: white;
  text-decoration: none;
  border-radius: 4px;
  transition: background 0.2s;
}
.fba-card .btn:hover {
  background: #3d8ba8;
  color: white;
}
</style>

<div class="fba-cards">
  <div class="fba-card">
    <h3>C. difficile Infection Model</h3>
    <img src="/assets/images/FBA/Cdifficile/Schema.png" alt="C. difficile Model">
    <div class="fba-card-content">
      <p>Study of metabolic reprogramming during <em>Clostridium difficile</em> infection, including the acquisition of antibiotic-resistant phenotypes through heme supplementation.</p>
      <a href="/epimod/Cdifficile/" class="btn">View Example</a>
    </div>
  </div>
  
  <div class="fba-card">
    <h3>E. coli Metabolic Modeling</h3>
    <img src="/assets/images/Framework.png" alt="E. coli Model">
    <div class="fba-card-content">
      <p>Integration of transcriptional data onto <em>Escherichia coli</em> genome-scale metabolic model (iML1515) growing on different regimes of carbon feeding.</p>
      <a href="/epimod/ecoli_modeling/" class="btn">View Example</a>
    </div>
  </div>
</div>

---

## epimod_FBAfunctions R Package

<div class="fba-cards">
  <div class="fba-card">
    <h3>epimod_FBAfunctions</h3>
    <img src="/assets/images/Framework.png" alt="epimod_FBAfunctions Package">
    <div class="fba-card-content">
      <p><strong>COBRA Model Processing:</strong> Read and modify COBRA MAT files, translate metabolic networks for epimod functions based on GLPK solver.</p>
      <p><strong>Sensitivity Analysis:</strong> Integrate Sobol's variance-based SA to classify reactions based on their impact on model outcomes.</p>
      <a href="https://github.com/qBioTurin/epimod_FBAfunctions" class="btn" target="_blank">View on GitHub</a>
    </div>
  </div>
</div>

---

## Reference

For more details on the FBA integration framework, please refer to our publication:

**Riccardo Aucello, Simone Pernice, Dora Tortarolo, Raffaele A Calogero, Celia Herrera-Rincon, Giulia Ronchi, Stefano Geuna, Francesca Cordero, Pietro Lió, Marco Beccuti**
UnifiedGreatMod: a new holistic modelling paradigm for studying biological systems on a complete and harmonious scale, Bioinformatics, Volume 41, Issue 3, March 2025
[ https://doi.org/10.1093/bioinformatics/btaf103 ](https://doi.org/10.1093/bioinformatics/btaf103 )

**Simone P, Laura F, et al.**  
Integrating Petri Nets and Flux Balance Methods in Computational Biology Models: a Methodological and Computational Practice. Fundamenta Informaticae. 2019;171(1-4):367-392. doi:10.3233/FI-2020-1888
[https://journals.sagepub.com/doi/abs/10.3233/FI-2020-1888](https://journals.sagepub.com/doi/abs/10.3233/FI-2020-1888)



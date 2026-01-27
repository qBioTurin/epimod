---
title: "GreatMod - Core Functionalities"
permalink: /functionalities/
layout: splash
intro: 
  - excerpt: 'GreatMod provides a versatile set of computational tools designed to address the complexity of biological systems, ranging from multi-scale integration to advanced stochastic simulations.'
---

{% include feature_row id="intro" type="center" %}

## Core Capabilities

<style>
.functionality-cards {
  display: flex;
  gap: 2rem;
  margin: 2rem 0;
  flex-wrap: wrap;
  justify-content: center;
}
.functionality-card {
  flex: 1;
  min-width: 300px;
  max-width: 500px;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  transition: transform 0.2s, box-shadow 0.2s;
  background: white;
}
.functionality-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 4px 16px rgba(0,0,0,0.15);
}
.functionality-card h3 {
  margin: 0;
  padding: 1.5rem;
  background: #f8f9fa;
  font-size: 1.3rem;
  text-align: center;
  border-bottom: 2px solid #e0e0e0;
}
.functionality-card img {
  width: 100%;
  height: 250px;
  object-fit: cover;
  display: block;
}
.functionality-card-content {
  padding: 1.5rem;
}
.functionality-card-content p {
  margin-bottom: 1.5rem;
  line-height: 1.6;
}
.functionality-card .btn {
  display: inline-block;
  padding: 0.6rem 1.5rem;
  background: #52adc8;
  color: white;
  text-decoration: none;
  border-radius: 4px;
  transition: background 0.2s;
}
.functionality-card .btn:hover {
  background: #3d8ba8;
  color: white;
}
</style>

<div class="functionality-cards">
  <div class="functionality-card">
    <h3>Integration with Flux Balance Analysis (FBA)</h3>
    <img src="/assets/images/FBA/Cdifficile/Schema.png" alt="FBA Integration">
    <div class="functionality-card-content">
      <p><strong>Multi-Scale Modeling:</strong> Seamlessly couple dynamic Petri Net models with genome-scale metabolic networks. Analyze host-pathogen interfaces and metabolic reprogramming at multiple biological scales.</p>
      <a href="/fba_integration/" class="btn">View Examples</a>
    </div>
  </div>
  
  <div class="functionality-card">
    <h3>Non-Markovian Stochastic Models</h3>
    <img src="/assets/images/Framework/GeneralWorkflow.png" alt="Non-Markovian Models">
    <div class="functionality-card-content">
      <p><strong>Beyond Memoryless Processes:</strong> Simulate stochastic events with general probability distributions. Capture complex temporal dynamics that standard Markovian models cannot represent.</p>
      <a href="/nonmarkovian/" class="btn">View Examples</a>
    </div>
  </div>
</div>

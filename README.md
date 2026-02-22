# Chaos Engineering on Kubernetes

A production chaos engineering lab focused on **reliability, observability, and controlled failure** in Kubernetes platforms.

## Formal SLO Statement

### Availability SLO

The Checkout and Payment APIs must maintain 99.9% availability over a rolling 30-day window, measured via successful HTTP responses from black-box monitoring.

### Latency SLO
95% of checkout requests must complete in under 500ms over a rolling 30-day window, measured using request duration histograms.

📊 Error Budget Calculation

30 days = ~43,200 minutes

0.1% failure allowed (100 - 99.9)

Allowed failure time:

43,200 × 0.001 = 43.2 minutes in a month.

---

## Focus

- Kubernetes operated as a **platform**
- GitOps-driven deployments
- Service mesh traffic control
- Metrics-first observability
- Hypothesis-driven chaos experiments
- Measured resilience improvements

---

## Stack

Kubernetes • ArgoCD • Istio • Helm  
Prometheus • Grafana • Alertmanager  
Chaos Mesh • Docker •  NewRelic • Linux *

---

## Architecture

![Architecture](./images/architecture.png)

---

## Method

1. Establish baseline metrics (latency, errors, saturation)
2. Define blast radius and safety controls
3. Inject controlled failures
4. Observe system behavior
5. Tune retries, autoscaling, and limits
6. Re-test and compare results

---


### External Dependency Chaos: CDN / Edge Failures

- Simulated DNS failures, TLS errors, and traffic blackholes
- Observed frontend and API resilience under edge outages
- Verified retries, fallbacks, and service mesh handling
- Correlated metrics, logs, and traces to measure impact

---

## Chaos Experiments

- Pod termination
- CPU stress
- Network latency & packet loss
- Node drain / failure

All experiments are **hypothesis-driven** and validated with metrics.

---

## Outcomes

- Confirmed Kubernetes self-healing behavior
- Identified retry amplification risks
- Improved stability via HPA, PDBs, and Istio tuning
- Reduced blast radius under failure
- Clear before/after observability data

---

⭐ Built with a production mindset: **design for failure, measure everything, improve continuously**.

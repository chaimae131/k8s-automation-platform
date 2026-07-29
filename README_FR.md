# Sécurisation et automatisation d'une infrastructure Kubernetes

![Kubernetes](https://img.shields.io/badge/Kubernetes-Orchestration-326CE5?logo=kubernetes)
![Terraform](https://img.shields.io/badge/Terraform-Infrastructure%20as%20Code-844FBA?logo=terraform)
![Ansible](https://img.shields.io/badge/Ansible-Automation-EE0000?logo=ansible)
![ArgoCD](https://img.shields.io/badge/ArgoCD-GitOps-FB4F14?logo=argo)
![Prometheus](https://img.shields.io/badge/Prometheus-Monitoring-E6522C?logo=prometheus)
![Grafana](https://img.shields.io/badge/Grafana-Visualization-F46800?logo=grafana)
![Loki](https://img.shields.io/badge/Loki-Logging-2C3E50)
![Falco](https://img.shields.io/badge/Falco-Runtime%20Security-00AEEF)
![DevSecOps](https://img.shields.io/badge/DevSecOps-Security%20Automation-success)

> Déploiement automatisé d'une infrastructure Kubernetes avec **Terraform** et **Ansible**, intégration d'un pipeline **GitOps** avec **ArgoCD**, et mise en place d'une plateforme complète d'observabilité et de sécurité basée sur **Prometheus**, **Grafana**, **Loki**, **Promtail** et **Falco**.

---

# 📖 Présentation

Ce projet a pour objectif d'automatiser le déploiement d'une infrastructure Kubernetes sécurisée en utilisant les pratiques DevOps et DevSecOps.

L'infrastructure est entièrement déployée sur **VMware Workstation Pro** à partir d'une machine virtuelle **Ubuntu Server** servant de modèle (template). Les machines virtuelles du cluster sont provisionnées automatiquement avec **Terraform**, puis configurées avec **Ansible**.

Une fois le cluster Kubernetes opérationnel, plusieurs composants sont déployés afin d'assurer :

- la gestion GitOps avec ArgoCD ;
- la supervision des ressources avec Prometheus ;
- la centralisation des logs avec Loki ;
- la visualisation des métriques et des logs avec Grafana ;
- la détection d'anomalies et des comportements suspects avec Falco.

---

# 🏗 Architecture


![Architecture du projet](docs/architecture.png)


```text
docs/architecture.png
```

L'architecture est composée des éléments suivants :

- **Ubuntu Desktop (Host)**
- **VMware Workstation Pro**
- **1 VM Ubuntu Server Template**
- **3 machines virtuelles Kubernetes**
  - 1 Master
  - 2 Workers
- **Terraform**
- **Ansible**
- **Kubernetes**
- **Helm**
- **ArgoCD**
- **Prometheus**
- **Grafana**
- **Loki**
- **Promtail**
- **Node Exporter**
- **Falco**

---

# 🎯 Objectifs

Ce projet répond aux objectifs suivants :

- automatiser la création d'une infrastructure Kubernetes ;
- appliquer des règles de hardening avant toute installation ;
- déployer automatiquement le cluster Kubernetes ;
- mettre en œuvre une approche GitOps ;
- superviser l'ensemble de l'infrastructure ;
- centraliser les logs des nœuds et des conteneurs ;
- détecter les anomalies de sécurité en temps réel.

---

# 🛠 Technologies utilisées

| Outil                  | Rôle                                    |
| ---------------------- | --------------------------------------- |
| Terraform              | Provisionnement des machines virtuelles |
| VMware Workstation Pro | Virtualisation                          |
| Ubuntu Server          | Système d'exploitation                  |
| Ansible                | Configuration automatique               |
| Kubernetes             | Orchestration                           |
| Helm                   | Gestion des applications Kubernetes     |
| ArgoCD                 | GitOps                                  |
| Prometheus             | Collecte des métriques                  |
| Grafana                | Visualisation                           |
| Loki                   | Centralisation des logs                 |
| Promtail               | Collecte des logs                       |
| Node Exporter          | Métriques système                       |
| Falco                  | Détection d'intrusions                  |


---

# 🚀 Déroulement du projet

## 1. Création de la machine virtuelle Template

Une machine virtuelle Ubuntu Server est créée manuellement sous VMware Workstation Pro.

Cette VM est préparée avec :

- OpenSSH Server
- configuration réseau
- utilisateur administrateur
- VMware Tools
- clés SSH
- mises à jour système

Cette machine devient ensuite le **template** utilisé par Terraform.

---

## 2. Provisionnement automatique avec Terraform

Terraform est utilisé pour automatiser le déploiement du cluster.

Il réalise automatiquement :

- le clonage du template Ubuntu Server ;
- la création des trois machines virtuelles ;
- l'attribution des ressources (CPU, RAM, disque) ;
- la configuration réseau ;
- la génération automatique du fichier **inventory** utilisé par Ansible.

Le cluster obtenu est composé de :

```text
Master
Worker-1
Worker-2
```

---

## 3. Configuration automatique avec Ansible

Une fois les machines créées, Ansible configure entièrement l'infrastructure.

Les playbooks sont exécutés dans l'ordre suivant.

### 🔒 Hardening

Avant l'installation de Kubernetes, plusieurs mesures de sécurité sont appliquées :

- désactivation du login root ;
- authentification SSH par clés ;
- configuration du pare-feu ;
- mises à jour système ;
- configuration sysctl ;
- sécurisation SSH ;
- suppression des services inutiles.

---

### ☸ Installation de Kubernetes

Installation automatique de :

- containerd
- kubeadm
- kubelet
- kubectl

Puis :

- initialisation du Master ;
- récupération du token ;
- ajout automatique des Workers.

Le cluster Kubernetes est alors entièrement opérationnel.

---

### ⚓ Installation de Helm

Helm est installé afin de simplifier le déploiement des applications Kubernetes.

---

### 🔄 Déploiement GitOps avec ArgoCD

ArgoCD est installé sur le cluster.

Il surveille un dépôt Git contenant les manifestes Kubernetes.

Chaque modification du dépôt est automatiquement synchronisée avec le cluster.

---

### 📊 Monitoring avec Prometheus

Prometheus collecte les métriques suivantes :

- CPU
- mémoire
- disque
- réseau
- métriques Kubernetes

---

### 📈 Grafana

Grafana permet de visualiser :

- les métriques Prometheus ;
- les logs Loki.

Des tableaux de bord facilitent la supervision de l'ensemble du cluster.

---

### 📝 Centralisation des logs

#### Loki

Loki stocke les journaux des applications et des nœuds.

#### Promtail

Promtail est déployé sous forme de **DaemonSet**.

Il collecte automatiquement :

- les logs système ;
- les logs Kubernetes ;
- les logs des conteneurs.

---

### 📡 Node Exporter

Node Exporter est également déployé en **DaemonSet** afin d'exposer les métriques système de chaque nœud.

---

### 🛡 Sécurité Runtime avec Falco

Falco surveille en permanence l'activité des conteneurs.

Il détecte notamment :

- les shells interactifs ;
- les accès suspects aux fichiers sensibles ;
- les privilèges élevés ;
- les comportements anormaux.

---

# 🔄 Workflow GitOps

```text
GitHub
   │
   ▼
ArgoCD
   │
   ▼
Synchronisation automatique
   │
   ▼
Cluster Kubernetes
```

Le dépôt Git constitue la source unique de vérité.

Toute modification des manifests Kubernetes est automatiquement appliquée au cluster.

---

# 📦 Déploiement


## Provisionnement des machines virtuelles

```bash
cd terraform

terraform init

terraform plan

terraform apply
```

## Déploiement du cluster

```bash
cd ../ansible

ansible-playbook playbooks/hardening.yml

ansible-playbook playbooks/kubernetes.yml

ansible-playbook playbooks/helm.yml

ansible-playbook playbooks/argocd.yml

ansible-playbook playbooks/monitoring.yml

ansible-playbook playbooks/logging.yml

ansible-playbook playbooks/falco.yml
```

---

# 📊 Résultat final

À la fin du déploiement, l'infrastructure comprend :

- ✅ Un cluster Kubernetes composé d'un Master et de deux Workers.
- ✅ Un provisionnement automatisé avec Terraform.
- ✅ Une configuration complète avec Ansible.
- ✅ Un cluster sécurisé grâce au hardening.
- ✅ Une plateforme GitOps avec ArgoCD.
- ✅ Une supervision centralisée avec Prometheus et Grafana.
- ✅ Une collecte centralisée des logs avec Loki et Promtail.
- ✅ Une surveillance système avec Node Exporter.
- ✅ Une détection d'anomalies en temps réel avec Falco.

---

# 🔮 Améliorations possibles

- Haute disponibilité du Control Plane Kubernetes
- Intégration d'Alertmanager
- Déploiement sur VMware vSphere
- Déploiement sur AWS, Azure ou GCP
- Intégration de HashiCorp Vault
- Analyse des images avec Trivy
- Politiques de sécurité avec Kyverno ou OPA Gatekeeper
- Pipeline CI/CD avec GitHub Actions ou GitLab CI

---

## 👥 Auteurs

Projet réalisé en équipe dans le cadre d'un projet de fin de semestre portant sur l'automatisation, la sécurisation et l'observabilité d'une infrastructure Kubernetes.

### Membres de l'équipe

- Chaima BISSI
- Hasnae AMANSAG
- Bassma HMAMMOUCH

### Ma contribution

J'ai principalement contribué aux aspects suivants :

- Déploiement et configuration du cluster Kubernetes ;
- Installation et configuration de Helm ;
- Déploiement et configuration d'ArgoCD pour la mise en place du workflow GitOps ;
- L'intégration de la stack Prometheus, Grafana et Loki ;

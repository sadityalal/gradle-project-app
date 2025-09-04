# Project-App CI/CD Pipeline with ArgoCD

Welcome! This project demonstrates a modern **CI/CD setup** using **GitHub Actions**, **Helm**, and **ArgoCD**.  

Whenever code is pushed, the pipeline automatically builds a Docker image, updates Helm chart values, and ArgoCD deploys it to the appropriate Kubernetes environment.

> **Best Practices:**  
> Developers should push their changes only to the `develop` branch. After thorough code reviews and testing, approved changes are merged into the `main` branch, which triggers the deployment to the production environment. This ensures stability and maintains a clean release process.


---

## Quick Links for Evaluation

If you want to test the pipeline quickly, you can use my demo repositories, which are pre-configured with secrets for review:

- **Application Repository**: [gradle-project-app](https://github.com/sadityalal/gradle-project-app)  
- **Helm Chart Repository**: [gradle-project-helm](https://github.com/sadityalal/gradle-project-helm)

These repos are ready for evaluation and demonstrate the pipeline in action.

---

## How the Pipeline Works

The pipeline follows a **branch-based promotion strategy**:

| Branch       | Action                                                                 | Result                                  |
|--------------|-----------------------------------------------------------------------|-----------------------------------------|
| `develop`    | Build, test, push Docker image, update Helm chart                     | ArgoCD deploys to **backend-dev**       |
| `main`       | Promote tested image from `develop`, update Helm chart               | ArgoCD deploys to **backend** (prod)   |

In simple terms:  
- `develop` = staging/dev environment  
- `main` = production environment  
- All deployments happen automatically, no manual intervention needed.

---

## Repository Structure

### Application Repository

Contains the **source code**, **Dockerfile**, and **GitHub Actions workflows**.

```bash
.
├── gradle-app/ # Java/Gradle application source code
│ ├── build.gradle
│ └── src/
├── Dockerfile # Build Docker image
├── .github/
│ └── workflows/
│ ├── develop.yaml # CI/CD workflow for develop branch
│ └── main.yaml # Promotion workflow for main branch
└── README.md
```


### Helm Chart Repository

Contains the **Helm charts**, **environment-specific values files**, and **ArgoCD application manifests**.

```bash
.
├── helm-chart/
│ ├── Chart.yaml # Helm chart metadata
│ ├── templates/ # Kubernetes templates
│ │ └── deployment.yaml
│ ├── values-gradle.yaml # Prod environment values
│ └── values-gradle-dev.yaml # Dev environment values
├── argo-app-dev.yaml # ArgoCD Application for dev
├── argo-app-prod.yaml # ArgoCD Application for prod
└── README.md
```


---

## CI/CD Flow

1. **Push to `develop` branch** in Application repo:
   - Compile and package the app (fat JAR)
   - Run unit tests
   - Build and push Docker image to registry
   - Update Helm chart (`values-gradle-dev.yaml` and `values-gradle.yaml`) in Helm repo
   - ArgoCD automatically deploys to **backend-dev**

2. **Merge `develop` → `main`**:
   - Fetch latest image tag from `develop` branch
   - Update Helm chart in `main` branch
   - ArgoCD automatically deploys to **backend** (production)

---

## Required Secrets

These secrets are used by the workflows (already configured in the demo repos):

| Secret Name             | Description                                                   |
|-------------------------|---------------------------------------------------------------|
| `IMAGE_REPO_NAME`       | Docker registry path (e.g., `ghcr.io/org/app`)                |
| `ARGO_REPO_NAME`        | Full name of Helm chart repository (e.g., `org/helm-repo`)    |
| `REPO_TOKEN`            | Personal Access Token (PAT) with read/write access            |

---

## ArgoCD Setup

The Helm repo contains **ArgoCD Application CRs** that auto-sync changes.

### Dev Environment (`gradle-app-dev`)

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: gradle-app-dev
  namespace: argocd
spec:
  project: default

  source:
    repoURL: https://github.com/sadityalal/gradle-project-helm
    path: helm-chart
    targetRevision: develop
    helm:
      valueFiles:
        - values-gradle-dev.yaml

  destination:
    server: https://kubernetes.default.svc
    namespace: backend-dev

  syncPolicy:
    automated:
      enabled: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
    retry:
      limit: 5
      backoff:
        duration: 10s
        factor: 2
        maxDuration: 3m0s

```

### Prod Environment (`gradle-app`)

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: gradle-app
  namespace: argocd
spec:
  project: default

  source:
    repoURL: https://github.com/sadityalal/gradle-project-helm
    path: helm-chart
    targetRevision: main
    helm:
      valueFiles:
        - values-gradle.yaml

  destination:
    server: https://kubernetes.default.svc
    namespace: backend

  syncPolicy:
    automated:
      enabled: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
    retry:
      limit: 5
      backoff:
        duration: 10s
        factor: 2
        maxDuration: 3m0s
      
```


## Deployment Flow Diagram

flowchart TD
  A [Developer Pushes to develop] --> B [Build & Test Application]
  B --> C[Build Docker Image]
  C --> D[Push to Registry]
  D --> E[Update Helm Chart - develop branch]
  E --> F[ArgoCD Syncs Dev Deployment]
  F --> G[Dev Environment Updated]

  H[Merge develop to main] --> I[Fetch Image Tag from develop]
  I --> J[Update Helm Chart - main branch]
  J --> K[ArgoCD Syncs Prod Deployment]
  K --> L[Production Updated]
 

## Quick Start

1. **Clone the Application Repo:**

```bash
git clone https://github.com/sadityalal/gradle-project-app.git
```

2. **Clone the Helm Chart Repo:**

```bash
git clone https://github.com/sadityalal/gradle-project-helm.git
```

## Deploy with ArgoCD

3. **Install ArgoCD** on your Kubernetes cluster.

4. **Apply ArgoCD Application manifests:**

```bash
kubectl apply -f argo-app-dev.yaml
kubectl apply -f argo-app-prod.yaml
```

- **Push code to `develop`** → ArgoCD automatically deploys to the dev environment.
- **Merge to `main`** → ArgoCD promotes the same image to the production environment.



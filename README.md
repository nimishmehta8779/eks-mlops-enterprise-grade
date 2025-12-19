# Enterprise MLOps Platform on EKS

This repository contains the Infrastructure-as-Code (Terraform) and GitOps configurations (Helm) for a production-grade MLOps platform on AWS.

## Architecture Guidelines

### Core Infrastructure
- **Compute**: Amazon EKS (Kubernetes 1.29+)
- **Network**: Single-AZ VPC (Cost-Optimized for Data Transfer)
- **Node Groups**:
    - `system`: On-Demand `t3.large` for control plane components.
    - `gpu`: On-Demand `g4dn.xlarge` (Tainted) for training/inference.
- **Storage**: EBS GP3, S3 for Artifacts, RDS (Optional) for Metadata.

### MLOps Stack
- **Orchestration**: Flyte (Code-First, Type-Safe) & Kubeflow Pipelines (DSL-based).
- **Training**: Ray (Distributed) on Kubernetes.
- **Serving**: KServe (Standard) & Ray Serve (High Performance).
- **GitOps**: ArgoCD.

## Directory Structure

```text
.
├── terraform/                  # Infrastructure Provisioning
│   ├── main.tf                 # Root Configuration
│   ├── modules/
│   │   ├── vpc/                # Custom Single-AZ VPC
│   │   └── eks/                # EKS Cluster + Node Groups
├── helm/                       # Application Packaging
│   ├── platform-app/           # ArgoCD App-of-Apps
│   └── values/                 # Environment overrides
└── workflows/                  # User Code Examples
    └── training_pipeline.py    # Flyte Workflow
```

## How to Deploy

### Prerequisites
- AWS CLI configured
- Terraform v1.0+
- `kubectl`

### Step 1: Provision Infrastructure

**CRITICAL COST WARNING**: This deployment costs ~$0.90/hour. Ensure you destroy it within 8-10 hours to stay under the $10 budget.

```bash
cd terraform
terraform init
terraform apply
```

### Step 2: Configure GitOps

Connect to the cluster:

```bash
aws eks update-kubeconfig --name mlops-platform --region us-east-1
```

Install ArgoCD (manual bootstrap):

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Apply the Platform Bootstrap:

```bash
kubectl apply -f helm/bootstrap.yaml
```

## Component Trade-offs

| Decision | Choice | Alternative | Justification |
|----------|--------|-------------|---------------|
| **Orchestrator** | **Flyte** | Kubeflow Pipelines | Flyte offers better type safety, data lineage, and caching for complex enterprise workflows. KFP is kept for legacy compatibility. |
| **Compute** | **AWS EKS** | SageMaker | EKS avoids vendor lock-in and allows full control over the compute environment (custom drivers, sidecars). |
| **Scaling** | **Karpenter** (Planned) | Cluster Autoscaler | Faster response time for GPU nodes and better handling of diverse instance types/spot (if enabled later). |
| **Serving** | **KServe** | SageMaker Endpoints | Unified Kubernetes CRD standardized across cloud/on-prem, integrated with Istio/Knative. |

## Operational Risks

1.  **Cost Management**: GPU instances (On-Demand) are expensive. Setup `kube-downscaler` or manual cron jobs to scale node groups to 0 at night.
2.  **Complexity**: Managing Kubeflow + Flyte + Ray is a high operational burden. Recommend picking ONE orchestrator for Day 2 operations (Flyte recommended).
3.  **Upgrade path**: EKS upgrades require careful node rotation. Integrated GitOps helps, but testing is required.
# eks-mlops-enterprise-grade

# Unified Dual-Cloud AI Engineer Roadmap
### Azure + AWS · 12–15 Months · 10 Certifications

---

## Guiding Principles

1. **AWS and Azure are equals.** Every major concept is built in both clouds, not mirrored as an afterthought.
2. **Certifications follow builds.** You study for a cert after you've already built what it tests. Never the reverse.
3. **Nothing is throwaway.** Every script, schema, and pipeline from Month 1 is a component of the Month 12 capstone.
4. **ML before LLM.** Classical ML foundations appear in Month 4 because AWS ML Specialty and real AI engineering require them.
5. **Cost discipline is a first-class concern.** Running two clouds simultaneously is expensive. Budget alerts and cost reviews are part of every month.

---

## Certification Schedule

| Cert | Target Month | Prerequisites Built By |
|------|-------------|------------------------|
| AZ-104 | Month 3 | Months 1–2 Azure builds |
| AWS SAA | Month 4 | Months 2–3 AWS builds |
| Terraform Associate | Month 5 | Months 3–4 IaC work |
| Docker Foundations Professional Certificate | Month 6 | Months 3–5 container work |
| CKA or CKAD | Month 7 | Months 3–6 Kubernetes depth |
| AI-900 (Azure AI Fundamentals) | Month 7 | Parallel to AI build work |
| AWS AI Practitioner | Month 8 | Month 7 AI service exposure |
| Azure AI Engineer (AI-102) | Month 10 | Months 7–9 Azure OpenAI + AI builds |
| AWS ML Engineer Associate | Month 11 | Months 4–10 ML + SageMaker work |
| AZ-305 | Month 13 | Full architecture depth |

> AZ-305 is intentionally last — it tests architecture judgment that only exists after you've built everything else.

---

## PHASE 1 — FOUNDATIONS (Months 1–3)

---

### Month 1 — Linux, Networking, Python, and Both Clouds from Day One

**Goal:** Operational on Linux, Python, and basic cloud in both Azure and AWS simultaneously.

#### Learn
- Linux CLI: navigation, permissions (chmod/chown), processes, systemd, journalctl
- SSH: key pairs, agent forwarding, config hardening, sshd_config
- TCP/IP: OSI model, IP addressing, subnets, CIDR notation
- DNS: resolution chain, A/AAAA/CNAME records, TTL, dig/nslookup
- HTTP/S, TLS handshake — what happens when you hit a URL
- NAT, routing basics
- Git: branching, rebasing, pull requests, commit discipline
- Bash scripting: variables, conditionals, loops, functions, exit codes
- Python: file I/O, JSON, requests, argparse, logging module
- Azure: account setup, CLI, portal orientation, cost alerts, resource groups
- AWS: account setup, CLI v2, IAM basics (root account hardening, MFA), cost alerts

#### Build
**Azure:**
- Provision Azure VM (B2s) via CLI only — no portal
- Harden: disable password auth, configure ufw, fail2ban
- Nginx serving a static page over HTTPS (self-signed cert)

**AWS:**
- Provision EC2 (t3.small) via AWS CLI
- Harden identically: key-pair only, Security Group (port 22 + 443 only), fail2ban
- Nginx serving a static page over HTTPS

**Both:**
- Python script: calls a public API, parses JSON, logs with timestamps, writes to file, handles errors
- Network diagram of both setups side-by-side: your machine → internet → cloud VNet/VPC → VM → Nginx → app
- README committed to GitHub documenting every decision (first portfolio entry)

#### Cert Thread
- AZ-104: begin Udemy/MS Learn modules for Identity and Governance domain

#### Cost Awareness
- Set $25/month budget alert in Azure
- Set $25/month budget alert in AWS
- Track actual spend weekly — both clouds together should be under $40/month at this stage

---

### Month 2 — Cloud Core, Security, and Identity

**Goal:** Deep understanding of compute, storage, networking, and identity in both clouds — built, not just read.

#### Learn
**Azure:**
- VNet, subnets, NSGs, VNet peering, private endpoints
- VMs, managed disks, Blob Storage, Azure Files
- RBAC: roles, scope levels, managed identities
- Key Vault: secrets, keys, certificates, access policies
- Azure Entra ID basics

**AWS:**
- VPC: subnets (public/private), route tables, internet gateways, NAT gateways
- EC2: instance types, AMIs, user data, instance profiles
- S3: buckets, policies, versioning, lifecycle rules, pre-signed URLs
- IAM: users, groups, roles, policies (managed vs inline), instance profiles
- Secrets Manager and Parameter Store
- Security Groups vs NACLs — this distinction appears in every AWS interview

**Shared Concepts:**
- Shared responsibility model
- Encryption at rest and in transit
- Least privilege as a design principle — not an afterthought

**Comparison Map (memorize this, it appears in every multi-cloud interview):**

| Azure | AWS | Key Difference |
|-------|-----|----------------|
| VNet + Subnet | VPC + Subnet | Azure NSGs at subnet level; AWS uses NACLs (stateless) + SGs (stateful) |
| NSG | Security Group + NACL | NSGs stateful; NACLs stateless — critical interview distinction |
| RBAC + Managed Identity | IAM Roles + Instance Profile | Same mental model, different API surface |
| Key Vault | Secrets Manager + KMS | Azure combines secrets and key management; AWS splits them |
| Blob Storage | S3 | Nearly identical concepts; different SDK |
| Entra ID | IAM Identity Center | Azure directory-first; AWS policy-first |
| Resource Groups | Tags + AWS Organizations | Azure groups are hard containers; AWS uses tags and accounts |

#### Build
**Azure:**
- Secure 3-tier architecture: Nginx frontend VM → FastAPI app → Postgres on a separate subnet
- NSGs: allow only necessary inter-tier traffic, document every rule and why it exists
- Managed identity for the app VM to read secrets from Key Vault (zero hardcoded credentials)
- FastAPI service: health check, data retrieval, write endpoint with Pydantic validation

**AWS:**
- Equivalent 3-tier: ALB → EC2 app tier (private subnet) → RDS Postgres (isolated subnet)
- Security Groups mirroring the Azure NSG rules — document what translated and what differed
- IAM role for EC2 instance to read from Secrets Manager (equivalent to Azure managed identity)
- Same FastAPI service deployed on EC2

#### Cert Thread
- AZ-104: complete Networking and Storage domains — take practice exam
- Aim for AZ-104 exam before end of Month 3

---

### Month 3 — Containers, Terraform, CI/CD

**Goal:** Reproducible, automated delivery in both clouds. Infrastructure defined as code.

#### Learn
- Docker: images, layers, multi-stage builds, volumes, networking, security scanning
- Terraform: providers, resources, variables, outputs, modules, state backends, workspaces
- GitHub Actions: triggers, jobs, steps, secrets, environment protection rules
- Azure: AKS provisioning, node pools, Azure Container Registry (ACR)
- AWS: EKS provisioning, ECR, ALB controller
- Kubernetes core: pods, deployments, ReplicaSets, services (ClusterIP/LoadBalancer/NodePort)
- Kubernetes config: ConfigMaps, Secrets, resource requests/limits
- Kubernetes health: liveness, readiness, startup probes
- Kubernetes networking: ingress controllers, ingress rules, TLS termination

#### Build
**Azure:**
- Containerize FastAPI service from Month 2 (minimal, hardened image)
- Push to ACR via CI pipeline
- Provision AKS cluster with Terraform — zero manual steps
- Deploy: Deployment, Service, Ingress manifests with health probes and resource limits
- Namespace separation: app namespace + monitoring namespace (prep for Month 9)

**AWS:**
- Push same container to ECR
- Provision EKS cluster with same Terraform module pattern — document what differed from AKS
- Deploy same manifests to EKS (minimal changes — this proves portability)

**Both:**
- CI/CD pipeline: lint → unit test → container scan (Trivy) → build → push → deploy
- Terraform state in Azure Blob Storage (Azure) and S3 backend (AWS)
- Capstone definition: write a one-page architecture document for the Month 12 system. Every month builds toward it.

#### Cert Thread
- **Take AZ-104** this month (foundations solid after 2 months of builds)
- AWS SAA: begin studying — focus on compute, storage, networking domains you've now built
- Terraform Associate: begin studying — you're already writing production Terraform

#### Kubernetes Scope Checklist
- Pod spec: image, env vars from ConfigMap and Secret, resource requests/limits
- Deployment with rolling update strategy
- Service of type LoadBalancer
- Ingress with TLS via cert-manager
- Liveness probe on /health; readiness probe on /ready
- `kubectl`: get, describe, logs, exec, apply, delete, rollout status

---

## PHASE 2 — DATA AND ML FOUNDATIONS (Months 4–6)

---

### Month 4 — Data Engineering, Postgres, and Classical ML

**Goal:** Build the data layer and ML foundations that feed the AI system. Classical ML is not skipped — AWS ML Specialty requires it.

#### Learn
- Postgres: schema design, data types, indexes (B-tree, GIN, partial), EXPLAIN ANALYZE, connection pooling
- SQL: joins, CTEs, window functions, upserts, transactions
- Pandas: read, clean, transform, validate, write pipelines
- Data validation: Pydantic for pipeline schemas, custom validators
- Document ingestion: PDF/text extraction, chunking strategies (fixed, sentence, semantic)
- scikit-learn fundamentals: supervised learning, train/test split, cross-validation, metrics, pipelines
- FastAPI depth: middleware, background tasks, lifespan events, error handlers, DB session injection
- Structured logging: JSON format, correlation IDs, log levels
- API testing: pytest, httpx TestClient, fixtures, test DB patterns

#### Build
**Azure:**
- ETL pipeline: ingest raw documents, clean and chunk, store in Postgres
- Schema designed for Month 7 RAG system: documents, chunks, embeddings tables (pgvector-ready)
  - Include: `processed` flag, `chunk_index`, `source_uri`, nullable `embedding` (vector)
- Train a simple scikit-learn classifier on a structured dataset
- Expose inference via FastAPI endpoint
- All endpoints emit structured JSON logs with request ID and duration

**AWS:**
- Same ETL pipeline deployed on EC2 or AWS Lambda (your choice — document the tradeoff)
- RDS Postgres with same schema
- Store the scikit-learn model artifact in S3 (precursor to SageMaker pattern)
- FastAPI on EC2 with the same endpoints

**Both:**
- Unit tests and integration tests against a test database
- Deploy updated service via the CI/CD pipeline from Month 3
- Add Postgres to Terraform configuration

#### Cert Thread
- **Take AWS SAA** this month (3 months of AWS builds = exam-ready)
- **Take Terraform Associate** if comfortable — you've been writing Terraform for 2 months
- AWS ML Specialty prep begins: study supervised learning, feature engineering, model evaluation

---

### Month 5 — Advanced ML, SageMaker, and Azure ML

**Goal:** Move from local ML to managed ML platforms. This is the foundation for AWS ML Specialty and Azure AI Engineer.

#### Learn
**AWS:**
- SageMaker: Studio, training jobs, built-in algorithms, model hosting, endpoints, Pipelines
- SageMaker Feature Store, Model Registry, Model Monitor
- AWS ML services: Comprehend, Rekognition, Textract, Translate (Practitioner-level AI services)
- Kinesis for streaming data ingestion

**Azure:**
- Azure Machine Learning: workspaces, compute clusters, datasets, experiments, pipelines
- Azure ML model registry, endpoints (managed online)
- Azure AI Services: Cognitive Services, Document Intelligence, Language Service

**Shared:**
- Feature engineering and selection
- Hyperparameter tuning strategies
- Model evaluation: confusion matrix, ROC-AUC, precision/recall tradeoffs
- MLOps concepts: versioning, reproducibility, model drift, monitoring

#### Build
**AWS:**
- Train a model in SageMaker (built-in XGBoost or Scikit container)
- Deploy as a SageMaker real-time endpoint
- Build a simple SageMaker Pipeline: preprocess → train → evaluate → register → deploy
- Store features in SageMaker Feature Store

**Azure:**
- Train the same model type in Azure ML
- Deploy as Azure ML managed online endpoint
- Build an Azure ML pipeline equivalent to the SageMaker one
- Compare: cost, latency, developer experience — write a decision log entry

**Both:**
- Update CI/CD pipelines to retrain and redeploy models on data change
- Add model performance monitoring endpoint to FastAPI

#### Cert Thread
- **Take Docker Certified Associate** (containers are mature by now)
- AWS ML Specialty: complete domain study for ML implementation and modeling
- Azure AI-900: begin — fast exam, low effort after this month's builds

---

### Month 6 — Kubernetes Deep Dive and Certification

**Goal:** Earn CKA or CKAD. Extend Kubernetes knowledge beyond deployment basics.

#### Learn
- Kubernetes storage: PersistentVolumes, PersistentVolumeClaims, StorageClasses
- Kubernetes security: RBAC, ServiceAccounts, PodSecurity standards, NetworkPolicies
- Kubernetes scheduling: node affinity, taints/tolerations, resource quotas
- Kubernetes operators: what they are, when to use them, examples (cert-manager, external-secrets)
- Helm: chart structure, values, templating, releases, rollbacks
- Service mesh concepts (Istio/Linkerd at conceptual level)
- Multi-cluster patterns: when to use multiple clusters, federation basics

#### Build
- Deploy all services via Helm charts (replace raw manifests from Month 3)
- Add NetworkPolicies restricting inter-pod traffic to minimum required
- Add external-secrets operator to sync Key Vault and Secrets Manager into Kubernetes Secrets
- RBAC audit: ensure every pod runs with a dedicated ServiceAccount with minimal permissions
- Set up Cluster Autoscaler on both AKS and EKS
- Load test the FastAPI service and observe Kubernetes HPA behavior

#### Cert Thread
- **Take CKA or CKAD** — CKAD if you're app-focused, CKA if you want ops depth
- **Take AI-900** — fast win, validates AI service knowledge from Month 5
- Begin AWS AI Practitioner study

---

## PHASE 3 — AI ENGINEERING (Months 7–9)

---

### Month 7 — LLM Application Engineering and RAG

**Goal:** Build a real retrieval-based AI application on the data layer from Month 4.

#### Learn
- Tokenization, context windows, why chunking strategy affects retrieval quality
- Embeddings: what they encode, cosine similarity, chunk size tradeoffs
- pgvector: ivfflat and hnsw indexes, similarity operators, approximate vs exact search
- Azure OpenAI: deployments, API surface, rate limits, token pricing
- AWS Bedrock: model access, inference API, Bedrock Knowledge Bases
- Prompt design: system prompts, few-shot examples, chain-of-thought, output constraints
- RAG architecture: retrieval pipeline, context assembly, grounding, citation patterns
- LLM evaluation: reference-based metrics, LLM-as-judge, human eval baselines
- Streaming responses with FastAPI and async generators
- Responsible AI: hallucination types, grounding strategies, refusal handling

#### Build
**Azure:**
- Embedding pipeline: process chunks from Month 4 Postgres through Azure OpenAI embeddings API, store via pgvector
- Vector search endpoint: cosine similarity with metadata filtering
- RAG endpoint: query → retrieve top-k → assemble context → LLM → response with citations
- Streaming endpoint using SSE
- Evaluation set: 20+ questions with expected answers and automated pass/fail scoring
- Feedback endpoint: thumbs up/down stored in Postgres with full retrieval context

**AWS:**
- Equivalent embedding pipeline using Amazon Bedrock (Titan Embeddings or Cohere)
- RAG system using Bedrock Knowledge Bases or manual pgvector on RDS
- Document the model selection decision: Azure OpenAI GPT-4o vs Bedrock Claude vs Bedrock Titan

**Both:**
- Prompt version control: system prompts as versioned files in the repo, never hardcoded strings
- LLM cost tracking per request (tokens in/out, model cost)

#### Cert Thread
- **Take AWS AI Practitioner** (Bedrock + AI services exposure from this month + Month 5)
- Azure AI Engineer (AI-102): begin serious study — deep overlap with this month's builds

---

### Month 8 — Advanced Prompt Engineering and AI Product Patterns

**Goal:** Move from "working RAG" to "production-quality AI features."

#### Learn
- Advanced prompt patterns: ReAct, tool use, structured outputs, function calling
- Agentic patterns: planning loops, tool orchestration, multi-step reasoning
- Azure OpenAI function calling and structured outputs
- AWS Bedrock Agents: agent definition, action groups, knowledge base integration
- LangChain and LlamaIndex: when they help, when they add complexity
- Fine-tuning concepts: when it helps, cost, data requirements, Azure fine-tuning API
- Context management: conversation history, summarization, sliding window
- Multi-modal: GPT-4V, Bedrock multi-modal — when to use, API surface
- Safety: content filters, Azure AI Content Safety, guardrails for Bedrock

#### Build
**Azure:**
- Add function calling to the RAG system: let the LLM call your FastAPI endpoints as tools
- Build an agent that can answer questions AND query live data via tool calls
- Add Azure AI Content Safety moderation layer to all LLM endpoints
- Fine-tune a small model on domain-specific data (if data volume allows)

**AWS:**
- Equivalent agent using Bedrock Agents with action groups pointing to Lambda functions
- Add Bedrock Guardrails for safety filtering
- Compare agent patterns: Azure OpenAI function calling vs Bedrock Agents — document tradeoffs

#### Cert Thread
- **Take Azure AI Engineer (AI-102)** this month — builds from Months 7–8 map directly to exam domains
- AWS ML Specialty: complete remaining domain study

---

### Month 9 — Observability and Production Hardening

**Goal:** Make the AI system observable, hardened, and production-grade.

#### Learn
- Prometheus: scrape configs, metric types (counter/gauge/histogram), PromQL
- Grafana: data source config, dashboard panels, alert rules
- Azure Monitor + Application Insights: distributed tracing, dependency maps
- AWS CloudWatch: metrics, logs, alarms, Container Insights for EKS
- AWS X-Ray: distributed tracing for AWS services
- Log aggregation: structured log shipping, Azure Log Analytics, CloudWatch Logs Insights
- IAM hardening: audit, least-privilege enforcement, access reviews
- Secret rotation: Key Vault rotation policies, Secrets Manager auto-rotation
- Azure Defender for Containers, AWS GuardDuty, Security Hub
- Release strategies: blue/green and canary in AKS and EKS
- Incident response: runbook structure, postmortem format

#### Build
**Both clouds:**
- Deploy Prometheus + Grafana into the monitoring namespace (provisioned in Month 3)
- Instrument FastAPI with prometheus_fastapi_instrumentator
- Add LLM-specific metrics: tokens per request, retrieval latency, eval score distribution
- Alert rules: p95 latency > 2s, error rate > 1%, pod crash loop
- AWS: CloudWatch dashboards mirroring Grafana panels
- Implement secret rotation: Azure OpenAI key (Key Vault rotation) + Bedrock credentials (Secrets Manager rotation)
- Add canary deployment to CI/CD: route 10% of traffic to new version, promote on green metrics
- Write the runbook: deploy, rollback, alert investigation, secret rotation
- Write one postmortem for a real or simulated incident

#### Cert Thread
- **Take AWS ML Specialty** — SageMaker + ML pipeline work from Months 4–8 is the foundation
- Begin AZ-305 study: architecture and design patterns

---

## PHASE 4 — ARCHITECTURE AND CAPSTONE (Months 10–12)

---

### Month 10 — Multi-Cloud Architecture and Advanced Patterns

**Goal:** Think and design at the architecture level. Required for AZ-305 and senior roles.

#### Learn
- Landing zone design: Azure Landing Zones, AWS Control Tower, multi-account strategy
- Network architecture: hub-spoke topology, transit gateways, VNet/VPC peering at scale
- High availability: availability zones, multi-region active-active vs active-passive
- Disaster recovery: RTO/RPO definitions, backup strategies, cross-region replication
- Cost optimization: reserved instances, savings plans, spot/preemptible instances, rightsizing
- Data sovereignty and compliance concepts: GDPR, HIPAA at the architecture level
- Event-driven architecture: Azure Service Bus, AWS SQS/SNS/EventBridge
- API Gateway patterns: Azure API Management, AWS API Gateway — throttling, auth, versioning
- Well-Architected Frameworks: Azure and AWS — five pillars, tradeoff reasoning

#### Build
- Redesign the capstone using event-driven patterns: document processing triggers via Service Bus / SQS
- Add multi-region read replica to Postgres (Azure and AWS)
- Implement async processing: document ingestion via message queue → worker pods → Postgres
- Add API Gateway layer in front of FastAPI: rate limiting, API key auth, request/response transformation
- Cost review: calculate monthly running cost of full capstone, identify top 3 optimization opportunities
- Architecture diagram: full system, polished in draw.io or Lucidchart

#### Cert Thread
- AZ-305: complete domain study, take practice exams

---

### Month 11 — Capstone Completion

**Goal:** Fully integrated, production-grade dual-cloud AI system.

#### Capstone System Requirements

The capstone must demonstrate every phase:

| Layer | Azure | AWS |
|-------|-------|-----|
| Infrastructure | Terraform-provisioned AKS, ACR, Key Vault, Postgres | Terraform-provisioned EKS, ECR, Secrets Manager, RDS |
| Application | FastAPI (containerized, Helm-deployed) | Same app on EKS |
| Data | ETL pipeline, pgvector schema, document ingestion | Equivalent on RDS + S3 |
| AI | RAG with Azure OpenAI, agents, streaming | RAG with Bedrock, Bedrock Agents |
| Observability | Prometheus + Grafana + App Insights | CloudWatch + X-Ray + Grafana |
| CI/CD | GitHub Actions: lint → test → scan → build → push → canary deploy | Same pipeline to ECR + EKS |
| Security | NSGs, managed identity, Key Vault rotation, Defender | SGs, IAM roles, Secrets Manager rotation, GuardDuty |

#### Build
- Wire all components together
- End-to-end test: document upload → ingestion → chunking → embedding → vector search → RAG response → monitoring metric
- Load test both deployments and compare performance
- Cost comparison: Azure vs AWS for the same workload — document findings
- Capstone README: overview, architecture diagram, technology choices with rationale, how to run locally and in cloud

---

### Month 12 — Portfolio, AZ-305, and Interview Readiness

**Goal:** Certify at the architecture level. Polish portfolio. Interview-ready.

#### Cert Thread
- **Take AZ-305** — architecture judgment built over 12 months

#### Portfolio Deliverables (Required, Not Optional)

| Deliverable | What It Demonstrates |
|-------------|----------------------|
| GitHub repo | Clean commit history from Month 1. Every month in its own branch/tag. |
| README | Architecture, tech choices with rationale, how to run it. |
| Architecture diagram | Full dual-cloud system: topology, services, data flow, integrations. |
| Decision log | 12 entries (one per month) — what you decided, considered, and why. Demonstrates judgment. |
| Cloud comparison doc | Azure vs AWS for each layer: what maps directly, what diverges, what you'd choose for a greenfield project and why. |
| Runbook | Deploy, rollback, alert investigation, secret rotation — for both clouds. |
| Postmortem | One real or simulated incident with root cause, timeline, remediation. |
| Technical write-up | 2,000–3,000 words. What you built, why each component, what you'd do differently. Publish on GitHub Pages. |
| Eval results | RAG evaluation scores across iterations, what improved, what you'd change in production. |
| Cert summary | All 10 certs listed with exam dates. Signals execution and follow-through. |

#### Interview Prep (Final Month)
- 3 system design questions per week: URL shortener, YouTube-scale video service, document Q&A at scale, ride-sharing backend, ML feature store
- STAR behavioral framework for all "tell me about a time" questions — your answers live in the decision log
- Portfolio walkthrough rehearsal: 20-minute version for a panel, 5-minute version for a screen
- Target roles: Cloud AI Engineer, ML Platform Engineer, Platform Engineer (AI/ML), AI Infrastructure Engineer

---

## 6-Month Milestone Checkpoint

If you need to show hiring progress at the 6-month mark, here is what you will have:

| Category | Status at Month 6 |
|----------|-------------------|
| Certifications | AZ-104 ✓, AWS SAA ✓, Terraform Associate ✓, Docker DCA ✓, CKA/CKAD ✓, AI-900 ✓ |
| Azure | 3-tier app, AKS, Terraform IaC, Key Vault, Managed Identity |
| AWS | EC2/RDS 3-tier app, EKS, Terraform IaC, IAM roles, Secrets Manager |
| Containers | Dockerized FastAPI, Helm charts, CI/CD pipeline, container scanning |
| Data | ETL pipeline, Postgres schema, scikit-learn model, ML platform exposure |
| AI | Not yet — begins Month 7 |
| Portfolio | Months 1–6 committed, README, architecture diagrams, decision log |

This is a legitimate cloud engineering portfolio. Not AI-complete, but cloud-complete and interview-viable for cloud engineer and platform engineer roles.

---

## Monthly Cost Budget (Both Clouds)

| Month | Estimated Monthly Cost |
|-------|----------------------|
| 1 | ~$30 (2 VMs, basic) |
| 2–3 | ~$60 (3-tier apps both clouds) |
| 4–5 | ~$80 (RDS/Postgres, ML compute) |
| 6 | ~$90 (EKS/AKS) |
| 7–9 | ~$120 (LLM API calls, vector search, monitoring) |
| 10–12 | ~$150 (full capstone, multi-region) |

**Total estimated cost: ~$900–$1,100 over 12 months.**
Use spot/preemptible instances wherever possible. Tear down non-essential resources after each build session.

---

## What You Can Skip or Defer

- **AZ-305** can slide to Month 15 if architecture domains feel weak — do not rush it
- **AWS ML Engineer Associate** can be deferred to Month 13 if ML work in Months 4–5 feels shallow
- **SageMaker Pipelines** depth can be reduced if you're not targeting MLOps-specific roles
- **Multi-region** builds in Month 10 can be architecture-only (no actual deploy) to save cost

Do not defer: dual-cloud builds from Month 1, the AI engineering phase, or the capstone.
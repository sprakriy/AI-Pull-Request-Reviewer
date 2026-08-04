# Automated AI Code Reviewer Pipeline

An event-driven GitOps and DataOps system that automatically reviews Pull Requests for security flaws, performance enhancements, and style optimizations. It uses a serverless AWS Lambda backend combined with Amazon Bedrock (Anthropic Claude 3.5 Sonnet) to post real-time code reviews directly back into your GitHub Pull Request comments.

## 🏗️ System & Workflow Architecture

The entire infrastructure is declared as code using Terraform, utilizing an event-driven automation loop triggered completely by repository pull request updates.

```mermaid
graph TD
    %% Custom Styling Defs
    classDef github fill:#181717,stroke:#333,stroke-width:2px,color:#fff;
    classDef terraform fill:#5C4EE5,stroke:#333,stroke-width:2px,color:#fff;
    classDef aws fill:#FF9900,stroke:#333,stroke-width:2px,color:#000;

    %% GitHub / CI/CD Space
    subgraph GH [GitHub Platform & Actions Engine]
        PR[1. PR Opened / Synchronized] -->|Triggers Workflow| Runner[GitHub Actions Runner]
        Runner -->|2. Request OIDC Token| AWS_IAM[AWS IAM OIDC Trust]
        Runner -->|3. Extract Code Changes| Diff[Generate pr.diff]
        Diff -->|4. Invoke Python SDK Payload| Lambda
        Comment[7. Post Markdown Review] -->|Appears on PR Timeline| PR
    end

    %% Infrastructure State Layer
    subgraph TF [Terraform Managed State]
        S3_State[(S3: ai-pr-reviewer-storage-dev)]
    end

    %% AWS Infrastructure
    subgraph AWS [Serverless AWS Ecosystem]
        AWS_IAM -->|Assumes OIDC Role| Runner
        
        subgraph Compute [Compute / API Layer]
            Lambda[5. AWS Lambda: ai-pr-reviewer-dev]
            L_Role[Least-Privilege Execution Role]
            L_Role -.->|Authorizes| Lambda
        end

        subgraph GenAI [AI Insights Engine]
            Bedrock[6. Amazon Bedrock Runtime]
            Claude[Anthropic Claude 3.5 Sonnet]
            Bedrock --> Claude
        end
    end

    %% Cross Boundary Interactions
    Lambda -->|bedrock:InvokeModel| Bedrock
    Claude -->|Returns Generated Insights| Lambda
    Lambda -->|Returns 200 OK + JSON Payload| Runner
    Runner -->|Output mapped to review_output.txt| Comment

    %% Apply CSS Classes
    class PR,Runner,Diff,Comment github;
    class S3_State terraform;
    class AWS_IAM,Lambda,L_Role,Bedrock,Claude aws;
```

---

## 🛠️ Technical Highlights & Pipeline Guardrails

* **Remote State and Encryption:** Configured with a dedicated remote Amazon S3 state storage backend tracking pipeline drift with native server-side encryption.
* **Secure OIDC Auth Federation:** Bypasses static, high-risk, long-lived AWS Access Keys. The GitHub Actions worker dynamically authenticates using OpenID Connect (OIDC) security tokens to assume a temporary IAM Execution role in AWS.
* **Strict Minimal Attack Surface:** Bypasses loose administrative wildcard privileges. The dedicated Lambda Execution role holds single-purpose attachments strictly mapping out `bedrock:InvokeModel` permissions.
* **Streamlined Context Analysis:** Uses a modularized standalone Python handler package compiling source file diff payloads directly into a structured Anthropic-native payload framework.

---

## 📂 Repository Directory Structure

```text
├── .github/
│   └── workflows/
│       └── review.yml          # GitHub Actions CI/CD automation workflow
├── modules/
│   └── pr_reviewer/
│       └── src/
│           └── lambda_function.py # Python Lambda handler translating diffs to Bedrock
├── backend.tf                  # Declares S3 remote state tracking settings
└── main.tf                     # Core configurations for Lambda, URLs, and IAM Policies
```

---

## 🚀 Getting Started

### 1. Configure the AWS Backend & Secrets
Ensure your target S3 bucket for the state tracking exists, and attach your GitHub Actions Runner OpenID Connect (OIDC) ARN mapping into the environment configurations.

### 2. Infrastructure Initialization & Deployment
Run the following standard execution blocks inside the workspace root:

```bash
# Initialize and sync remote state plugins
terraform init

# Validate configuration text syntax 
terraform validate

# Provision your AWS Lambda infrastructure resources
terraform apply
```

### 3. CI/CD Activation
Once deployed, simply commit code or open a **Pull Request** on this repository. The `.github/workflows/review.yml` action will immediately fire, run the Git differences, invoke your cloud instance, and write the analysis markdown report right onto your active workspace pull request line automatically.

<img width="1336" height="814" alt="Image" src="https://github.com/user-attachments/assets/8be6669e-f2eb-4e83-a774-86214b00bc45" />


<img width="1336" height="814" alt="Image" src="https://github.com/user-attachments/assets/dc15f662-82a8-43b8-b034-a862d6d8a54f" />

<img width="1336" height="814" alt="Image" src="https://github.com/user-attachments/assets/bc6b30eb-00c1-47df-8b75-e330951f4125" />

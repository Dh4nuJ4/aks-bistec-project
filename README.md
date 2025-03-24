```markdown
# AKS Cluster Setup and Nginx Deployment

This project demonstrates the creation of an Azure Kubernetes Service (AKS) cluster using Terraform and the deployment of a simple Nginx web server with Kubernetes. The goal was to set up an AKS cluster, deploy a basic application, and expose it via a LoadBalancer service, all while documenting the process, challenges, and lessons learned.

## Project Overview
- **Infrastructure**: An AKS cluster with 1 node, created using Terraform.
- **Application**: A simple Nginx web server deployed with 2 replicas, exposed via a LoadBalancer Service.
- **Tools Used**: Terraform, Azure CLI, kubectl, Git, Visual Studio Code (VS Code).

## Setup Instructions

### 1. Prerequisites
Before starting, ensure you have the following tools installed:

#### Visual Studio Code (VS Code)
- **Purpose**: Used as the code editor.
- **Installation**: Download from [code.visualstudio.com](https://code.visualstudio.com/) and install.
- **Verification**: Open VS Code and ensure it runs.

#### Git
- **Purpose**: Used for version control.
- **Installation**: Download from [git-scm.com](https://git-scm.com/) and install.
- **Verification**: Run `git --version` in PowerShell to confirm installation.

#### Terraform
- **Purpose**: Used to define and provision the AKS cluster as Infrastructure as Code (IaC).
- **Installation**:
  - Download the 64-bit Windows binary (amd64) from [terraform.io/downloads](https://www.terraform.io/downloads.html).
  - Extract the zip file to a directory (e.g., `C:\terraform`).
  - Add the directory to your system PATH environment variable.
- **Verification**: Run `terraform --version` to confirm it’s installed correctly.

#### Azure CLI
- **Purpose**: Used to interact with Azure services and retrieve cluster credentials.
- **Installation**:
  - Use the Microsoft Installer (MSI) with PowerShell:
    ```powershell
    $ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri https://aka.ms/installazurecliwindowsx64 -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; Remove-Item .\AzureCLI.msi
    ```
- **Verification**: Run `az --version` to ensure it’s installed.

#### kubectl
- **Purpose**: Used to manage the Kubernetes cluster and deploy the application.
- **Installation**:
  - Download the binary with:
    ```powershell
    curl.exe -LO "https://dl.k8s.io/release/v1.32.0/bin/windows/amd64/kubectl.exe"
    ```
  - Place `kubectl.exe` in a directory (e.g., `C:\kubectl`), and add it to your system PATH.
- **Verification**: Run `kubectl version --client` to confirm installation.

#### Azure Account
- Create an Azure account at [portal.azure.com](https://portal.azure.com/) if you don’t have one.
- Log in to Azure with:
  ```powershell
  az login
  ```
  - This opens a browser prompt. Sign in with your Azure account email.
  - Select your subscription (e.g., enter `1` if you have one subscription, or press Enter to continue).
- Verify the login with:
  ```powershell
  az account show
  az account list --output table
  ```

### 2. Create the AKS Cluster
- **Step 1**: Create a project folder:
  ```powershell
  mkdir aks-bistec_project
  cd aks-bistec_project
  ```
- **Step 2**: Create a `main.tf` file:
  ```powershell
  code main.tf
  ```
  Add the following content (replace `subscription_id` with your own):
  ```hcl
  provider "azurerm" {
    features {}
    subscription_id = "7c9496c4-ef8b-44de-9b09-1c2022099887"
  }

  resource "azurerm_resource_group" "rg" {
    name     = "bistec-dhanu-aks-rg"
    location = "East US"
  }

  resource "azurerm_kubernetes_cluster" "aks" {
    name                = "bistec-dhanu-aks-cluster"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    dns_prefix          = "dhanu-aks"
    default_node_pool {
      name       = "default"
      node_count = 1
      vm_size    = "Standard_B2s"
    }
    identity {
      type = "SystemAssigned"
    }
  }
  ```
- **Step 3**: Initialize Terraform:
  ```powershell
  terraform init
  ```
  - This creates a lock file and downloads the required provider plugins.
- **Step 4**: Preview the changes:
  ```powershell
  terraform plan
  ```
- **Step 5**: Apply the configuration:
  ```powershell
  terraform apply
  ```
  - Type `yes` to approve. This creates the resource group and AKS cluster (takes ~10 minutes).

### 3. Connect to the Cluster
- Retrieve the kubeconfig file:
  ```powershell
  az aks get-credentials --resource-group bistec-dhanu-aks-rg --name bistec-dhanu-aks-cluster
  ```
- Verify the connection:
  ```powershell
  kubectl get nodes
  ```
  - This should list the cluster’s node (e.g., `aks-default-27072721-vmss000000`).

### 4. Additional Configurations
- Initially, `kubectl get nodes` showed `<none>` in the `ROLES` column. To fix this, I set custom labels:
  ```powershell
  kubectl label node aks-default-27072721-vmss000000 kubernetes.io/role=node
  kubectl label node aks-default-27072721-vmss000000 role=webserver
  ```
- Verify the changes:
  ```powershell
  kubectl get nodes
  kubectl describe node aks-default-27072721-vmss000000
  ```

### 5. Deploy the Nginx App
- **Step 1**: Create a `k8s` subfolder:
  ```powershell
  mkdir k8s
  cd k8s
  ```
- **Step 2**: Create `deployment.yaml`:
  ```powershell
  code deployment.yaml
  ```
  Add:
  ```yaml
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: nginx-deployment
  spec:
    replicas: 2
    selector:
      matchLabels:
        app: nginx
    template:
      metadata:
        labels:
          app: nginx
      spec:
        containers:
        - name: nginx
          image: nginx:latest
          ports:
          - containerPort: 80
  ```
- **Step 3**: Create `service.yaml`:
  ```powershell
  code service.yaml
  ```
  Add:
  ```yaml
  apiVersion: v1
  kind: Service
  metadata:
    name: nginx-service
  spec:
    selector:
      app: nginx
    ports:
    - port: 80
      targetPort: 80
    type: LoadBalancer
  ```
- **Step 4**: Apply the configurations:
  ```powershell
  kubectl apply -f deployment.yaml
  kubectl apply -f service.yaml
  ```
- **Step 5**: Verify the deployment:
  ```powershell
  kubectl get pods
  ```
  - This should show 2 replicas running.
- **Step 6**: Check the Service:
  ```powershell
  kubectl get service nginx-service
  ```
  - This returns an external IP (e.g., `128.203.103.199`).
- **Step 7**: Test the app:
  ```powershell
  curl http://128.203.103.199
  ```
  - This should return the Nginx welcome page, confirming success.

### 6. Add the Contributor Role
- The assignment required adding an "AKS contributor role." Update `main.tf` to include the role assignment:
  ```hcl
  resource "azurerm_role_assignment" "aks_contributor" {
    scope                = azurerm_resource_group.rg.id
    role_definition_name = "Contributor"
    principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
  }
  ```
- Apply the change:
  ```powershell
  terraform apply
  ```
  - Type `yes` to approve.

### 7. Clean Up
- To avoid costs, destroy the resources:
  ```powershell
  terraform destroy
  ```
  - Type `yes` to approve.

## Challenges Faced
- **Subscription ID Error**: My first `terraform plan` failed because I omitted the `subscription_id` in `main.tf`. I resolved this by adding it to the `provider "azurerm"` block.
- **Understanding Permissions**: The assignment mentioned assigning the AKS Contributor role, which initially caused confusion. After researching, I learned that the SystemAssigned identity automatically provides the necessary permissions within the cluster’s resource group. Since I wasn’t accessing other Azure services like ACR or Key Vault, additional role assignments weren’t required for this project.
- **Learning Kubernetes**: As a beginner, Kubernetes concepts like Deployments, Services, and node labels were initially overwhelming. I overcame this by experimenting with YAML files and `kubectl` commands.

## Learning Curve
This project provided hands-on experience with key DevOps tools and concepts:
- **Terraform**: I learned to define infrastructure as code and troubleshoot configuration errors.
- **Azure CLI**: I gained proficiency in managing Azure authentication and cluster credentials.
- **Kubernetes (AKS)**: I deepened my understanding of Deployments, Services, node labeling, and LoadBalancer exposure.
- **Git and VS Code**: I reinforced my skills in version control and editing configuration files efficiently.

This journey bridged the gap between theoretical knowledge and practical application in cloud infrastructure and container orchestration.

## Results
- Successfully created an AKS cluster with 1 node.
- Set custom node labels (`kubernetes.io/role=node` and `role=webserver`) to replace `<none>`.
- Deployed an Nginx app with 2 replicas, accessible at `http://128.203.103.199`.
```
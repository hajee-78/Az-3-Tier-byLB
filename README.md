Azure 3-Tier Architecture with Terraform

This repository provisions a 3-tier application architecture in Azure using Terraform.
The stack includes Web, Application, and Database tiers, each secured with Network Security Groups (NSGs) and balanced with Azure Load Balancers for high availability.

🌐 Architecture Overiew

The deployment consists of:

1 Resource Group
3 Subnets (Web, App, DB)
6 Virtual Machines (2 per tier, using Availability Sets for HA)
3 Load Balancers (Public for Web, Internal for App & DB)
Network Security Groups (NSGs applied to each subnet)
Bastion Host (for secure VM access since RDP is blocked externally)

**High-level Architecture Diagram**

![image](https://github.com/hajee-78/Azure-3-Tier-Stack/assets/55215524/b106220c-bd82-48cf-b6cf-aea76e544c0b)


🏗️ Code Structure

|-- main.tf          # Core Terraform configuration (resources)

|-- variable.tf      # Variables declaration

|-- terraform.tfvars # Environment-specific values

|-- README.md        # Documentation

🚀 Deployment Steps

terraform init    # Initialize provider plugins & backend                    

terraform fmt     # Format code for readability

terraform plan    # Preview changes before applying

terraform apply   # Deploy infrastructure

⚙️ Customization

Adjust NSG rules in main.tf to open only the required ports (e.g., 80 for Web, 443 for App, 1433 for DB).
Update terraform.tfvars for region, VM sizes, or custom tags.

📌 Goal

This project demonstrates a scalable, secure, and modular 3-tier architecture in Azure using Infrastructure as Code (IaC) principles.
It can be extended further with:
Azure Monitor / Log Analytics integration
VNet Peering with hub-spoke topology
Auto-scaling with Virtual Machine Scale Sets (VMSS)












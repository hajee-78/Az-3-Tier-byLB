Azure 3-Tier Architecture with Terraform

This repository provisions a 3-tier application architecture in Azure using Terraform.
The stack includes Web, Application, and Database tiers, each secured with Network Security Groups (NSGs) and balanced with Azure Load Balancers for high availability.

🌐 Architecture Overview

The deployment consists of:

1 Resource Group
3 Subnets (Web, App, DB)
6 Virtual Machines (2 per tier, using Availability Sets for HA)
3 Load Balancers (Public for Web, Internal for App & DB)
Network Security Groups (NSGs applied to each subnet)
Bastion Host (for secure VM access since RDP is blocked externally)

**High-level Architecture Diagram**

![image](https://github.com/hajee-78/Azure-3-Tier-Stack/assets/55215524/b106220c-bd82-48cf-b6cf-aea76e544c0b)

**Solution**

The terraform code structure as follows

|-- main.tf // Contains the resource blocks that define the resources to be created in the target cloud provider. 

|-- vars.tf // Variables declaration used in the resource block.

|-- terraform.tfvars // Declare the environment specific default values for variables.

# Deployment Steps

**terraform init** - To initializes a working directory containing configuration files and installs plugins for required providers.

**terraform fmt** - To rewrite Terraform configuration files to a canonical format and style. This command applies a subset of the Terraform language style conventions, along with other minor adjustments for readability.

**terraform plan** - The terraform plan command creates an execution plan, which lets you preview the changes that Terraform plans to make to your infrastructure.

**terraform apply** - The terraform apply command executes the actions proposed in a Terraform plan to create, update, or destroy infrastructure.













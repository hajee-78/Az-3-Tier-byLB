# Azure-3-Tier-Stack
This repository helps to build a 3-tier architecture in Azure using HCL Terraform.
----------------------------------------------------------------------------------
Web Tier, Application Tier, and Data Tier are the three logical layers into which the modern application deployment divides the application using a technique known as 3-tier architecture. The web tier responds to user requests, the application tier manages and processes the data, and the data tier stores the data.

**Goal**

Provision a 3-tier application with terraform consisting of 1 Resource Group, 3 load balancers, and 6 virtual machines. In detail, we are creating three subnets namely Web, App and DB then control the traffic between subnets thorugh network security groups. We are deploying virtual machines under availability sets to achieve High Availability. Public and Internal load balancers will manage the incoming traffic to Web, App and DB subets respectively. 

**High-level Architecture Diagram**

![image](https://github.com/hajee-78/Azure-3-Tier-Stack/assets/55215524/b106220c-bd82-48cf-b6cf-aea76e544c0b)

**Solution**

The terraform code structure as follows

|-- main.tf // Contains the resource blocks that define the resources to be created in the target cloud provider. 

|-- vars.tf // Variables declaration used in the resource block.

|-- terraform.tfvars // Declare the environment specific default values for variables.

#Deployment Steps

**terraform init** - To initializes a working directory containing configuration files and installs plugins for required providers.

**terraform fmt** - To rewrite Terraform configuration files to a canonical format and style. This command applies a subset of the Terraform language style conventions, along with other minor adjustments for readability.

**terraform plan** - The terraform plan command creates an execution plan, which lets you preview the changes that Terraform plans to make to your infrastructure.

**terraform apply** - The terraform apply command executes the actions proposed in a Terraform plan to create, update, or destroy infrastructure.













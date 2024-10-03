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

|-- main.tf 

|-- vars.tf 

|-- terraform.tfvars 












# demo-ilb-ase

This guide will show how to configure DNS for your ILB App Service environment and how to use Azure DevOps to deploy code to that ASE.

## Prerequisites

- The Azure DevOps command line extension: az extension add --name azure-devops
- An ILB App Service Environment (will take approx. 1hr to deploy)
- An app or two deployed to an app service environment (will take approx. 1hr to deploy) on the ASE
- An additional subnet for containers

## Configure DNS

## Configure Azure Container as DevOps Agent

## Notes

In the current state of Azure, we usually recommend a service other than ILB ASE (e.g., AKS or a multitenant app service with vnet integration), but this guide should be helpful if have a particular use case.  

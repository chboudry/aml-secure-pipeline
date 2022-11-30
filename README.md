# aml-secure-pipeline

Minimalistic example on how to trigger a AML pipeline from a Github pipeline, but with the specifics to allow it to run on a secure AML workspace.

This example comes from the following [official azureml example](https://github.com/Azure/azureml-examples/blob/main/.github/workflows/cli-jobs-pipelines-nyc-taxi-pipeline.yml) but I removed all the unecessary bits that we do not use.

## Note 

### Hosted runners

For Github to be able to reach out to a private VNET that contains your AML workspace, you need to set up a self hosted runner into the VNET, or a VNET peered to it.
There are multiple ways to implement a Github runner : 
    - You can set up a VM in Azure
    - you can set up a container in Azure, either in Azure Container Instance or in AKS
AKS is a bit overkill for this example. 
Azure Container instance is the next best thing as it can be cheaper than a VM and dockerfile are easy to read to understand what's going on.
For this reason, this code example will use a docker container on Azure Container Instance as a github self-hosted runner.

Note : From a network perspective, the runner will initiate the connection to Github, there is no inbound traffic to open. Outbound traffic to github is HTTPS.

### Authentication

There are multiple ways for Github runner to authenticate so that it can run actions in Azure : 
- [Create a service principal](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure?tabs=azure-portal%2Cwindows#use-the-azure-login-action-with-a-service-principal-secret) and provide the credentials as part of Github secret, it is the easiest way,but as a secret is used, it implies key rotation which is not ideal.
- Create a service principal with a certificated stored in a runner is a solution but certificates do expire, so let's avoid it.
- We can also [use a managed identity](https://www.cloudwithchris.com/blog/github-selfhosted-runner-on-azure/) that is tied to the runner as long as the runner is a Azure resource that's support it (VM & ACI do)
- Use an App registration with [federated crendentials](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure?tabs=azure-portal%2Cwindows#use-the-azure-login-action-with-openid-connect). This is fairly new and the benefit is we don't have to store any credentials. This is what we are going to use here.

Managed identity is quite nice but to my opinion App registration with federated credentials is a bit more secure as it set up an additionnal security to tie the runner to a specific Github repository. 
For this reason, this code example will use App registration with federated credentials.

### Public vs Private pipeline

There is **one unique** difference between a public and a secure pipeline from a code perspective : you edit the github pipeline and set "self-hosted" instead of "ubuntu-latest" as the value of "runs-on:".

Aside that, you obviously need to set up your self-hosted runner in Azure and register it to GitHub.

## Prerequisites

1. Have a secure AML workspace running in Azure
1. have a compute cluster available called "cpu-cluster" (or change the pipeline.yml to match the name of your cluster)
1. [Create an app registration within Azure AD with OpenID Connect](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure?tabs=azure-portal%2Cwindows#use-the-azure-login-action-with-openid-connect)
1. On the resource group the ML workspace is, provide RBAC contributor permission to the app registration (you can reduce permissions depending on your use case)
1. Define the following secrets in Github that are going to be use by the Github pipeline to authenticate: 
   - CLIENT_ID : the app registration client ID
   - TENANT_ID : your tenant ID
   - SUBSCRIPTION_ID : your subscription ID
1. Define the following secrets in Github that are going to be use by the setup.sh script: 
   - RG_NAME
   - LOCATION
   - WORKSPACE_NAME
1. Run the workflow trough Github UI.


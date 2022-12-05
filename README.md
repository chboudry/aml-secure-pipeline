# aml-secure-pipeline

Example on how to trigger a AML pipeline from a Github pipeline, but with the specifics to allow it to run on a secure AML workspace.

We will use an Azure Container Instance to host the runner.

## Note 

### Public vs Private Github Pipeline

There is **one unique** difference between a public and a secure pipeline from a code perspective : you edit the github pipeline and set "self-hosted" instead of "ubuntu-latest" as the value of "runs-on:".

Aside that, you obviously need to set up your self-hosted runner in Azure and register it to GitHub.

### Hosted runners

For Github to be able to reach out to a private VNET that contains your AML workspace, you need to set up a [self-hosted runner](https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners) into the VNET, or a VNET peered to it.
There are multiple ways to implement a Github runner : 
- You can set up a VM in Azure
- you can set up a container in Azure, either in Azure Container Instance or in AKS

From a [network perspective](https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners#communication-between-self-hosted-runners-and-github), the runner will initiate the connection to Github, there is no inbound traffic to open. Outbound traffic to github is HTTPS.

To build the docker image, you can either :
- Use internal build function within a public Azure Container registry
- Use dedicated agent pool (preview) within a private ACR
- Build the container as part of a GH pipeline on a GH runner and push it to a public ACR

### Authentication

There are multiple ways for Github runner to authenticate so that it can run actions in Azure : 
- [Create a service principal](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure?tabs=azure-portal%2Cwindows#use-the-azure-login-action-with-a-service-principal-secret) and provide the credentials as part of Github secret, it is the easiest way,but as a secret is used, it implies key rotation which is not ideal.
- Create a service principal with a certificated stored in a runner is a solution but certificates do expire, so let's avoid it.
- We can also [use a managed identity](https://www.cloudwithchris.com/blog/github-selfhosted-runner-on-azure/) that is tied to the runner as long as the runner is a Azure resource that's support it (VM & ACI do)
- Use an App registration with [federated crendentials](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure?tabs=azure-portal%2Cwindows#use-the-azure-login-action-with-openid-connect). This is fairly new and the benefit is we don't have to store any credentials. This is what we are going to use here.

Managed identity is quite nice but to my opinion App registration with federated credentials is a bit more secure as it set up an additionnal security to tie the runner to a specific Github repository. 
For this reason, this code example will use App registration with federated credentials.

### Diagram

![architecture-schema](docs/architectureschema.png)

1. The self-hosted runner opens a HTTPS channel to Github.
1. A Github pipeline targetting the self hosted runner is triggered.
1. The self-hosted runner runs the pipeline locally and cli commands can access the secure AML workspace.

## Step By Step

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


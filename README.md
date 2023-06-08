# Hello Zarf Tutorial

_This repo contains a basic webserver to be deployed by [Zarf](https://github.com/defenseunicorns/zarf.git). The webserver has a `k8s` folder with Kubernetes manifests and a `hello-zarf-chart` folder with a helm chart. The first step is to spin up a Kind cluster and initialize Zarf._

**TOC**
- [Prerequisites](#prerequisites)
- [Create Cluster](#create-cluster)
- [Deploy without Zarf](#deploy-webserver-without-zarf)
- [Deploy Helm chart with Zarf](#deploy-helm-chart-with-zarf)
- [Deploy Kubernetes manifests with Zarf](#deploy-kubernetes-manifests-with-zarf)
- [Cleanup](#cleanup)


## Prerequisites

- [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/)
- [Zarf CLI](https://docs.zarf.dev/docs/the-zarf-cli/)
- [jq (Nice to have)](https://jqlang.github.io/jq/download/)

For the easiest way to get started on mac:

``bash
brew tap defenseunicorns/tap && brew install zarf
```

## Create Cluster 

```bash
kind create cluster --name=zarf
```

## Deploy Webserver without Zarf

_This step is to show you what you will be looking for Zarf to deploy._
 
```yaml
kubectl create -f -<<EOF
apiVersion: v1
kind: Namespace
metadata:
  creationTimestamp: null
  name: webserver
spec: {}
status: {}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: hello-zarf
  name: hello-zarf
  namespace: webserver
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hello-zarf
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: hello-zarf
    spec:
      containers:
      - image: docker.io/cmwylie19/hello-zarf
        name: hello-zarf
        command: ["./hello-zarf"]
        resources: {}
status: {}
---
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    app: hello-zarf
  name: hello-zarf
  namespace: webserver
spec:
  ports:
  - port: 8081
    protocol: TCP
    targetPort: 8081
  selector:
    app: hello-zarf
status:
  loadBalancer: {}
EOF
# Sleep so we can wait for condition=Ready
sleep 2
# wait for it...
kubectl wait pod --for=condition=Ready -l app=hello-zarf --timeout=180s -n webserver
```

Check pod and service are running.   

```bash
kubectl get svc,po -n webserver -l app=hello-zarf
```

output

```bash
NAME                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/hello-zarf   ClusterIP   10.96.168.209   <none>        8081/TCP   83s

NAME                             READY   STATUS    RESTARTS   AGE
pod/hello-zarf-c558dd559-gppvt   1/1     Running   0          83s
```

Curl against service to ensure app is working.   

```bash
kubectl run curler --image=nginx:alpine --rm -it --restart=Never  -- curl hello-zarf.webserver.svc.cluster.local:8081/hi
```

output

```bash
#output 
Let's kick Zarf's tires!🦄pod "curler" deleted
```


Clean up the manual deployment,svc,and pod

```bash
kubectl delete deploy,svc,po -l app=hello-zarf -n webserver --force --grace-period=0

kubectl delete ns webserver
```

Next, we will deploy the werbserver through the helm chart with Zarf

## Install Zarf in the cluster

Running `zarf init` installs Zarf onto the target cluster. After `zarf-init` press (Y) to install the package, (n) for logging, and (n) for gitea

```bash
zarf init 
```

output

```bash
Saving log file to
/var/folders/v0/slmrzc4s6kx4n7jb77ch9fc80000gn/T/zarf-2023-06-08-09-11-52-2308707066.log

         *,                                                                              
         *(((&&&&&/*.                                                                    
          *(((((%&&&&&&&*,                                                               
           *(((((((&&&&&&&&&*              ,,*****,.                      **%&&&&&(((((( 
            *(((((((((&&&&&&&@*    **@@@@@@&&&&&&&&&&@@@@@**         */&&&&&&((((((((((  
              *((((((///(&&&&&&@@@@&&&&@@@@@@@@@&&&&&&&&&&&&&&@/* *%&&&&&&/////((((((*   
                *(((///////&&&&&&&&&&&&&@@@@@@@@@&&&&&&&&&&&&&&&&&(%&&&/**///////(/*     
       */&&&&&&&&&&&&&&&&*/***&%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&/*******///*         
   *&%&&&&&&&&&&&&&&&&&&&&&&&***&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&****/&&&&&&&&&&&&(/*
 */((((((((((((((///////******%%&&&&&&&&//&@@*&&&&&&&&&&&&&&&&&&&#%&&&&*/####(/////((((/.
     */((((((((((///////******%%%%%%%%%(##@@@//%&%%%%%%%&%&%%&&/(@@(/&&(***///////(((*   
          ***(((((/////********%%%%%%%/&%***/((%%%%%%%%%%%%%%%%(#&@*%/%%***/////**       
            *&&%%%%%%//*******%%%%%%%%@@****%%/%%%%%%%%%%%%%%%%%%***@@%%**(%%%&&*        
          *&&%%%%%(////******/(%%%%%%%@@@**@@&%%%%%%%%%%%%%%%%%(@@*%@@%%*****////%&*     
        *&%%%%%#////////***/////%%%%%%*@@@@@/%%%%%%%%%%%%%%%%%%%%@@@@%%*****///////((*   
       *%%%%((((///////*    *////(%%%%%%##%%%%%%%%%%%(%%%%*%%%%%%%%%%%*                  
      *(((((((/***            */////#%%%%%%%%%%#%%%%%%%%%%%%%%%%%%%%#*                   
                   %%(           ,*///((%%%%%%%%(**/#%%%##**/%%%%%*                      
                 %%%&&&&           *///*/(((((########//######**                         
                 %&&&&&*          *#######(((((((//////((((*                             
                                  ###%##############(((#####*                            
                   %@&&          *&#(%######*#########(#####/                            
                   /&&* ..       ,&#(/%####(*#########/#####/             #%@%&&&        
             **         &&     ./%##((*&####/(#######(#####*(*            %&&&&&&        
           *@%%@*             *&#####((((####*(#####(*###(*(##*              ,  %@&      
          *@%%%%*            *%######((((*%####/*((*%####/*(###*  *                      
         *@%%%%%%*      *##* **#(###((((///#*#*(((((/#**#((*(##**#,*/##*,    %@&&        
         *@%%%*%%%*  ****,*##/*#*##(((((((/(((((((((/(((*(((((###########*,  #&&#        
         *@%%%*(%%%/*   **######(#((..((((((((((((((((((*  ,*(#####(((((*,               
         *@%%%#(*%%%%*   ,**/####(* */(((((((((((((((((*     ,**,                        
          *@%%%*(/(%%%%/*     ******(((((((((((*(((((*                                   
           *@%%%#(((*/%%%%%%##%%*((((((((((((**((((*                                     
            *@%%%%*(((((((((((((((((((((((*/%*((*.             (&&&(                     
             ,*%%%%%%*((((((((((((((((**%%%**,                (&                         
                *%%%%%%%%%(/*****(#%%%%%**                      &%                       
                   ,**%%%%%%%%%%%%%***                                                   
                                                                                         
             ,((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((,          
                         .....(((((((/////////////////((((((((.....                      
                                                                                         
            ///////////////      ///////      *****************  ***************,        
                    ////.       ///  ////     *///          ***  ****                    
                 ////,         ///    ////    *///////////////.  /////**/******          
              /////          //////////////   *///      *///     ///*                    
           ./////////////// ////         ///  *///        ////   ///*                    
                                                                                         


  ✔  All of the checksums matched!                                                                                            
  ✔  Loading Zarf Package /Users/cmwylie19/.zarf-cache/zarf-init-arm64-v0.26.4.tar.zst                                        

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

kind: ZarfInitConfig
metadata:
  name: init
  description: Used to establish a new Zarf cluster
  version: v0.26.4
  architecture: arm64
  aggregateChecksum: 1137879a8815937f84327def4b5317e83940305beb6a238b48b8be84f0e5cffc
build:
  terminal: fv-az616-317
  user: runner
  architecture: arm64
  timestamp: Wed, 17 May 2023 02:48:30 +0000
  version: v0.26.4
  migrations:
  - scripts-to-actions
  - pluralize-set-variable
  differential: false
  registryOverrides: {}
components:
- name: zarf-injector
  description: |
    Bootstraps a Kubernetes cluster by cloning a running pod in the cluster and hosting the registry image.
    Removed and destroyed after the Zarf Registry is self-hosting the registry image.
  required: true
  cosignKeyPath: cosign.pub
  files:
  - source: sget://defenseunicorns/zarf-injector:arm64-2023-02-09
    target: "###ZARF_TEMP###/zarf-injector"
    executable: true
- name: zarf-seed-registry
  description: |
    Deploys the Zarf Registry using the registry image provided by the Zarf Injector.
  required: true
  charts:
  - name: docker-registry
    releaseName: zarf-docker-registry
    version: 1.0.0
    namespace: zarf
    valuesFiles:
    - packages/zarf-registry/registry-values.yaml
    - packages/zarf-registry/registry-values-seed.yaml
    localPath: packages/zarf-registry/chart
  images:
  - library/registry:2.8.2
- name: zarf-registry
  description: |
    Updates the Zarf Registry to use the self-hosted registry image.
    Serves as the primary docker registry for the cluster.
  required: true
  charts:
  - name: docker-registry
    releaseName: zarf-docker-registry
    version: 1.0.0
    namespace: zarf
    valuesFiles:
    - packages/zarf-registry/registry-values.yaml
    localPath: packages/zarf-registry/chart
  manifests:
  - name: registry-connect
    namespace: zarf
    files:
    - packages/zarf-registry/connect.yaml
  - name: kep-1755-registry-annotation
    namespace: zarf
    files:
    - packages/zarf-registry/configmap.yaml
  images:
  - library/registry:2.8.2
- name: zarf-agent
  description: |
    A Kubernetes mutating webhook to enable automated URL rewriting for container
    images and git repository references in Kubernetes manifests. This prevents
    the need to manually update URLs from their original sources to the Zarf-managed
    docker registry and git server.
  required: true
  actions:
    onCreate:
      before:
      - cmd: make init-package-local-agent AGENT_IMAGE_TAG="v0.26.4" ARCH="arm64"
  manifests:
  - name: zarf-agent
    namespace: zarf
    files:
    - packages/zarf-agent/manifests/service.yaml
    - packages/zarf-agent/manifests/secret.yaml
    - packages/zarf-agent/manifests/deployment.yaml
    - packages/zarf-agent/manifests/webhook.yaml
  images:
  - ghcr.io/defenseunicorns/zarf/agent:v0.26.4
- name: logging
  description: |
    Deploys the Promtail Grafana & Loki (PGL) stack.
    Aggregates logs from different containers and presents them in a web dashboard.
    Recommended if no other logging stack is deployed in the cluster.
  charts:
  - name: loki-stack
    releaseName: zarf-loki-stack
    url: https://grafana.github.io/helm-charts
    version: 2.9.10
    namespace: zarf
    valuesFiles:
    - packages/logging-pgl/pgl-values.yaml
  manifests:
  - name: logging-connect
    namespace: zarf
    files:
    - packages/logging-pgl/connect.yaml
  images:
  - docker.io/grafana/promtail:2.7.4
  - grafana/grafana:8.3.5
  - grafana/loki:2.6.1
  - quay.io/kiwigrid/k8s-sidecar:1.19.2
- name: git-server
  description: |
    Deploys Gitea to provide git repositories for Kubernetes configurations.
    Required for GitOps deployments if no other git server is available.
  actions:
    onDeploy:
      after:
      - maxTotalSeconds: 60
        maxRetries: 3
        cmd: ./zarf internal create-read-only-gitea-user
      - maxTotalSeconds: 60
        maxRetries: 3
        cmd: ./zarf internal create-artifact-registry-token
  charts:
  - name: gitea
    releaseName: zarf-gitea
    url: https://dl.gitea.io/charts
    version: 7.0.4
    namespace: zarf
    valuesFiles:
    - packages/gitea/gitea-values.yaml
  manifests:
  - name: git-connect
    namespace: zarf
    files:
    - packages/gitea/connect.yaml
  images:
  - gitea/gitea:1.18.5-rootless
variables:
- name: K3S_ARGS
  description: Arguments to pass to K3s
  default: --disable traefik
- name: REGISTRY_EXISTING_PVC
  description: "Optional: Use an existing PVC for the registry instead of creating a new one. If this is set, the REGISTRY_PVC_SIZE variable will be ignored."
- name: REGISTRY_PVC_SIZE
  description: The size of the persistent volume claim for the registry
  default: 20Gi
- name: REGISTRY_PVC_ACCESS_MODE
  description: The access mode of the persistent volume claim for the registry
  default: ReadWriteOnce
- name: REGISTRY_CPU_REQ
  description: The CPU request for the registry
  default: 100m
- name: REGISTRY_MEM_REQ
  description: The memory request for the registry
  default: 256Mi
- name: REGISTRY_CPU_LIMIT
  description: The CPU limit for the registry
  default: "3"
- name: REGISTRY_MEM_LIMIT
  description: The memory limit for the registry
  default: 2Gi
- name: REGISTRY_HPA_MIN
  description: The minimum number of registry replicas
  default: "1"
- name: REGISTRY_HPA_MAX
  description: The maximum number of registry replicas
  default: "5"
- name: REGISTRY_HPA_ENABLE
  description: Enable the Horizontal Pod Autoscaler for the registry
  default: "true"
- name: GIT_SERVER_EXISTING_PVC
  description: "Optional: Use an existing PVC for the git server instead of creating a new one. If this is set, the GIT_SERVER_PVC_SIZE variable will be ignored."
- name: GIT_SERVER_PVC_SIZE
  description: The size of the persistent volume claim for git server
  default: 10Gi
- name: GIT_SERVER_CPU_REQ
  description: The CPU request for git server
  default: 200m
- name: GIT_SERVER_MEM_REQ
  description: The memory request for git server
  default: 512Mi
- name: GIT_SERVER_CPU_LIMIT
  description: The CPU limit for git server
  default: "3"
- name: GIT_SERVER_MEM_LIMIT
  description: The memory limit for git server
  default: 2Gi
constants:
- name: REGISTRY_IMAGE
  value: library/registry
- name: REGISTRY_IMAGE_TAG
  value: 2.8.2
- name: AGENT_IMAGE
  value: defenseunicorns/zarf/agent
- name: AGENT_IMAGE_TAG
  value: v0.26.4

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This package has 9 artifacts with software bill-of-materials (SBOM) included. You can view them now
in the zarf-sbom folder in this directory or to go directly to one, open this in your browser:
/Users/cmwylie19/hello-zarf/zarf-sbom/sbom-viewer-docker.io_grafana_promtail_2.7.4.html

* This directory will be removed after package deployment.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

? Deploy this Zarf package? Yes

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

name: logging
charts:
- name: loki-stack
  releaseName: zarf-loki-stack
  url: https://grafana.github.io/helm-charts
  version: 2.9.10
  namespace: zarf
  valuesFiles:
  - packages/logging-pgl/pgl-values.yaml
manifests:
- name: logging-connect
  namespace: zarf
  files:
  - packages/logging-pgl/connect.yaml
images:
- docker.io/grafana/promtail:2.7.4
- grafana/grafana:8.3.5
- grafana/loki:2.6.1
- quay.io/kiwigrid/k8s-sidecar:1.19.2

Deploys the Promtail Grafana & Loki (PGL) stack. Aggregates logs from different containers and
presents them in a web dashboard. Recommended if no other logging stack is deployed in the cluster.
? Deploy the logging component? No

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

name: git-server
actions:
  onDeploy:
    after:
    - maxTotalSeconds: 60
      maxRetries: 3
      cmd: ./zarf internal create-read-only-gitea-user
    - maxTotalSeconds: 60
      maxRetries: 3
      cmd: ./zarf internal create-artifact-registry-token
charts:
- name: gitea
  releaseName: zarf-gitea
  url: https://dl.gitea.io/charts
  version: 7.0.4
  namespace: zarf
  valuesFiles:
  - packages/gitea/gitea-values.yaml
manifests:
- name: git-connect
  namespace: zarf
  files:
  - packages/gitea/connect.yaml
images:
- gitea/gitea:1.18.5-rootless

Deploys Gitea to provide git repositories for Kubernetes configurations. Required for GitOps
deployments if no other git server is available.
? Deploy the git-server component? No

                                                                                       
  📦 ZARF-INJECTOR COMPONENT                                                           
                                                                                       

  ✔  Copying 1 files                                                                                                          
  ✔  Waiting for cluster connection (5m0s timeout)                                                                            
  ✔  Gathering cluster information                                                                                            
  ✔  Attempting to bootstrap the seed image into the cluster                                                                  

                                                                                       
  📦 ZARF-SEED-REGISTRY COMPONENT                                                      
                                                                                       

  ✔  Loading the Zarf State from the Kubernetes cluster                                                                       
  ✔  Processing helm chart docker-registry:1.0.0 from Zarf-generated helm chart                                               

                                                                                       
  📦 ZARF-REGISTRY COMPONENT                                                           
                                                                                       

  ✔  Pushed 1 images to the zarf registry                                                                                     
  ✔  Processing helm chart docker-registry:1.0.0 from Zarf-generated helm chart                                               
  ✔  Starting helm chart generation registry-connect                                                                          
  ✔  Processing helm chart raw-init-zarf-registry-registry-connect:0.1.1686229912 from Zarf-generated helm chart              
  ✔  Starting helm chart generation kep-1755-registry-annotation                                                              
  ⠋  Processing helm chart raw-init-zarf-registry-kep-1755-registry-annotation:0.1.1686229912 from Zarf-generated helm chart (  ✔  Processing helm chart raw-init-zarf-registry-kep-1755-registry-annotation:0.1.1686229912 from Zarf-generated helm chart  

                                                                                       
  📦 ZARF-AGENT COMPONENT                                                              
                                                                                       

  ✔  Pushed 1 images to the zarf registry                                                                                     
  ✔  Starting helm chart generation zarf-agent                                                                                
  ✔  Processing helm chart raw-init-zarf-agent-zarf-agent:0.1.1686229912 from Zarf-generated helm chart                       
  ✔  Zarf deployment complete


Application | Username  | Password                 | Connect
Registry    | zarf-push | WjMx4wfduHbOz8Pk2UJ5oF56 | zarf connect registry
```


**What's going on behind the scenes**  
### Nerd Notes
you can skip to [the helm chart deployment of the webserver if you like](#deploy-helm-chart-with-zarf), as we have successfully initialized `zarf` in the cluster.  
  

After `zarf init` you will see an image registry pod in the zarf namespace, used to store images which are later saved in the final compressed tarball  (similar to a `docker save <image repo>/<user>/<container> -o <container>.tar`). There will be two replicas of the `agent-hook`, a mutating webhook that renames the images from the previous image registry like docker.io to the internal image registry deployed in the namespace. 

```bash
kubectl get po -n zarf
```

output

```bash
NAME                                    READY   STATUS    RESTARTS   AGE
agent-hook-6f879d6866-9tgj5             1/1     Running   0          5m28s
agent-hook-6f879d6866-bpdjm             1/1     Running   0          5m28s
zarf-docker-registry-86d76d95b7-7cb8f   1/1     Running   0          5m34s
```

Also a `zarf-state` secret which contains the credentials for components Zarf uses.

```bash
kubectl get secret zarf-state -n zarf --template='{{.data.state}}' | base64 -d  | jq
```

output

```json
{
  "zarfAppliance": false,
  "distro": "kind",
  "architecture": "arm64",
  "storageClass": "standard",
  "agentTLS": {
    "ca": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURXVENDQWtHZ0F3SUJBZ0lRYnhkQS8zYjhYOFNzb3d5clFvMjZPekFOQmdrcWhraUc5dzBCQVFzRkFEQTMKTVJjd0ZRWURWUVFLRXc1YVlYSm1JRU52YlcxMWJtbDBlVEVjTUJvR0ExVUVBeE1UWTJFdWNISnBkbUYwWlM1NgpZWEptTG1SbGRqQWVGdzB5TXpBMk1EZ3hNekV5TVROYUZ3MHlOREEyTVRjeE16RXlNVE5hTURjeEZ6QVZCZ05WCkJBb1REbHBoY21ZZ1EyOXRiWFZ1YVhSNU1Sd3dHZ1lEVlFRREV4TmpZUzV3Y21sMllYUmxMbnBoY21ZdVpHVjIKTUlJQklqQU5CZ2txaGtpRzl3MEJBUUVGQUFPQ0FROEFNSUlCQ2dLQ0FRRUFycy9maE5hMTFUK0ZuSTlsRGJBeQp4aHpqYTZYRkVoa0hLeW95MkYwYllHU25uTWRnQmprOEtjdld6d3ZaRlpzZ0V1SGhqcVhIWHJrV3k0aDRxRHQyCmFxY2RlNnEwTjdodkhCNXl4U0hsMHNyVDhzVDRiUEZXcUh5RkpjOUVVMGNiL2dXVlB3YXNvek9zczdoMWhRN1YKbUNsUDhxQkF0YWJ6ZG1oYncyd0pkcDFNVmFGQXh1N3RLc2p6OXdnbXp6SUJYNThjbmp0ZkdET3YxaUVidXVUSgpkcitTb0lWc3c4QVpoVllRQXo5NHo1Q1d2TWdHM2lHbmpoMHJrbVFQbHFJZWx6K1pOVTd0TGFaUnpEdVI5VkcyClF2eUxJQW91ek94MHpwVlNZTjNVd2l5QnVqemdRQ2hSWjFva3BLUzVYc0VpSld0OE5SamFtQTJCa3pZVEdRNkYKRXdJREFRQUJvMkV3WHpBT0JnTlZIUThCQWY4RUJBTUNBb1F3SFFZRFZSMGxCQll3RkFZSUt3WUJCUVVIQXdFRwpDQ3NHQVFVRkJ3TUNNQThHQTFVZEV3RUIvd1FGTUFNQkFmOHdIUVlEVlIwT0JCWUVGQk5GVUlLamxnMmtMUXYwClh1V05pYUJxV3F4Y01BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQkFsVlBQQ3Bzdkw5SEZnYjJxK3cvRmdnOW0KV2QzVEFoTXpKWUpEVUIwMFBVallhK3RUd0MwbWREOUVtYzgyc0VRaUpxV1k5Qk1LaWJsc3VMZ05TRVN3TnlWdwpIem5ad0Q2dlZEeHZRRGEzRVcvWGxyVEkyVGt3SXFTaHpmaWVHTTZ4V00vUzBES01rVXBTVnl1cGVYQzR2VU1pCkZCL2xKTWpsZjVWQi93c3k0ZTNBR1ozanlod1NldVVmM2tUYXVyb0lYUS9vK1ozb29BcnlhbW1yYUJDUGhmb2cKaVFFbm5ocG1halBsZGw1UlZFS2x2UnNpVzdrTkZKTDlsbllGTkhTMjJNRnhET2xUYVdleEpIZ09qLysza1JjLwpjczdKbDk0UFZKM283N3NWcGlmS21jK0hWRityUUVvOGhUS3RHNU5jTWxQMmdKVGs0TURMaFdPbmRIUFcKLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=",
    "cert": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURjekNDQWx1Z0F3SUJBZ0lSQVBOZWNHZEZWWXFYcXVheFUxaVZIVVV3RFFZSktvWklodmNOQVFFTEJRQXcKTnpFWE1CVUdBMVVFQ2hNT1dtRnlaaUJEYjIxdGRXNXBkSGt4SERBYUJnTlZCQU1URTJOaExuQnlhWFpoZEdVdQplbUZ5Wmk1a1pYWXdIaGNOTWpNd05qQTRNVE14TWpFeldoY05NalF3TmpFM01UTXhNakV6V2pBMU1SVXdFd1lEClZRUUtFd3hhWVhKbUlFTnNkWE4wWlhJeEhEQWFCZ05WQkFNVEUyRm5aVzUwTFdodmIyc3VlbUZ5Wmk1emRtTXcKZ2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLQW9JQkFRQ1Rkb0NXamx4VjdIZCs0S3NIdGluaAo4VVNkVHk5TCs3a2tZWXFOY0tXYWZxc2hiNzhGWkVSWXB5Zm1TZ0ZFTENEa0NXZUFGYVdHSGE1SWlMTEFNZjZkCjBMYkU4TC9RUFVQZ3ZQSzd2ZVBjelVkMHhRc1JlalJXMkdLWEVNS3VUNDFQcnFjNXkzWUFLa3FQUDgvcUg2anMKWVBHaEJyTjJ3Qk5xb0pkVkU2TUtnRHZCT09GU25WeVhvd2FzbEEwT1NtcUVQWXlPeER3VG4vNlFTeFBPZjlLYwowdFpnWVBRSS9VaUdYQXU3UU8ydzdQakk0aGNYOHpJeUNYV0FjNy9Tb2p1MVBPL2s1bjUvenNNeXBNbys4dCtGClAyV3E2WjBidTluaC83RFRtRkN3OWdCV29JeDluYWU1dVVkYmE5Z2RENkRCZDFIRlV0c09WbWFremJaZWt0NTkKQWdNQkFBR2pmREI2TUE0R0ExVWREd0VCL3dRRUF3SUZvREFUQmdOVkhTVUVEREFLQmdnckJnRUZCUWNEQVRBTQpCZ05WSFJNQkFmOEVBakFBTUI4R0ExVWRJd1FZTUJhQUZCTkZVSUtqbGcya0xRdjBYdVdOaWFCcVdxeGNNQ1FHCkExVWRFUVFkTUJ1Q0UyRm5aVzUwTFdodmIyc3VlbUZ5Wmk1emRtT0hCSDhBQUFFd0RRWUpLb1pJaHZjTkFRRUwKQlFBRGdnRUJBQ1VWZWt5MlFHQklMT2l4ckhXbFVzRXZNM0hML3Z4Tm83M2N3amVuVnIzS2hTeXRxMUlpc1REYwplcXUvblpidXVSNzFrMHVHalVrV1NDa1A2RDVyOG1ERzE5SDIvZFN4dnBhdjJ1THRtWkFkZnZEYkNDR0JXS0dICnNmWVJ1djFEeU1sTDUwRDN3ZTZUMG1rWVJYZkRob2g1SmFYOXhEVG0vbEpObVkzdmYvMTRUcVQxL21IdFArUmIKbHJBeS95YTYxSW1GdkZFU253OTdmcjlPdEFyRU0xM0k4OWZ2KzlJWUQzaVJyTStJZGpLQVIyOFV6a3Q0aXhpcwphaDlmRjRtSDlpcEhMQjRyTHZlRk9Wa0h4cjQ1SVB6MjlRVlVhME91NXY1SENFZ2lqdkdpMmFMZGczeUozcGlWCkhNRTlxRnl6Y0g1TithKzNhbGp0aWhFd1BEZnlPY0k9Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K",
    "key": "LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFb3dJQkFBS0NBUUVBazNhQWxvNWNWZXgzZnVDckI3WXA0ZkZFblU4dlMvdTVKR0dLalhDbG1uNnJJVysvCkJXUkVXS2NuNWtvQlJDd2c1QWxuZ0JXbGhoMnVTSWl5d0RIK25kQzJ4UEMvMEQxRDRMenl1NzNqM00xSGRNVUwKRVhvMFZ0aGlseERDcmsrTlQ2Nm5PY3QyQUNwS2p6L1A2aCtvN0dEeG9RYXpkc0FUYXFDWFZST2pDb0E3d1RqaApVcDFjbDZNR3JKUU5Ea3BxaEQyTWpzUThFNS8ra0VzVHpuL1NuTkxXWUdEMENQMUlobHdMdTBEdHNPejR5T0lYCkYvTXlNZ2wxZ0hPLzBxSTd0VHp2NU9aK2Y4N0RNcVRLUHZMZmhUOWxxdW1kRzd2WjRmK3cwNWhRc1BZQVZxQ00KZloybnVibEhXMnZZSFErZ3dYZFJ4VkxiRGxabXBNMjJYcExlZlFJREFRQUJBb0lCQVFDVFlsZDNJdVpLd3NOVQpQbnp5Z2pFdU1CUmlIZWlweXZmcTBzckdQeFpsYWNEazlHazVuRk5yUC9aekJ2aHBDS24vQVI4L04yTnV2bStZCjgzZWsvTkw5TE1QZjVyZndDNnV5RFdlV0dWNkxLMmtGM29NSGZ0cWRDanpQdStLNGthNHRPK1RMc1AxSmdQdHcKWFZrVEtYMk9jLzVNOFFPaDVxd0JZR3lnamJYaElYRXo0M21RdUw2SkNxNGU5emVNQnpBNjdHN1ZPYXRIZG1iZgp5cmV0K3FjdTc1WVk5dFEyTUVxUWk4YlV1NDN6YWh6RW12a3pKelFyMHk0ZU1Kd2NHV3B4VlVZWlJTQ1RHRkpzClF3a1Bpa0ZQckJMSjFHK1poM1NoQVdMWXVNRFluTldWZHh6UUNwc0xNek0wVXM4WlROZ2JsTTQ4aWJlbWgvbmQKRE5MdkZBWkpBb0dCQU1HaFZ6aEFUWVJjblZ6WXFFNUVBM0hUcUJxaUM3YkhCR3d0M3RnTDhadElEeGJ2Y2p6aAppNTVWd3BSQVQ5emxNSzRPTERGL1dXNGR3VXVBRm5mNDI1dlErUC9xWjNDSXp0MmR3R1g4YXJVa3o5RG85SUlCCkFJOHdFV3N4M2dxMGx5YmcrNDVlcXQwcjh2WTV1bERrUjEwUzlMODBKMWwzQ29uY2NqMjFpYUNiQW9HQkFNTDIKT1hORytJZGdmMnpXTExUbnVDVjJhdzZKM09PZ0FQZURxUTVkMUlHQkJ0dFNGYkVub1MrL2dCcThIVlg5OU9ZUQpuNURUTnlXb05uVzFESXpVT2x5NG1HdkVaS1NjeVFUR2M0UHlLaTBLM05UT2o0NHdEUkZsM0NkZm1lUWVBYUxpCkdMTTEyR24zSkJFdHJSczJVLzdVOE1OaVQxUXBBNWJLQ1FHNVZuTEhBb0dBSnBDNDYzWTdPanFzQ1BzS0FwU2YKVHdPRi9zLzVuMHppUDUyZlBjNmJMMzlacWdyRTZRVlBKcGtVS1N6cCt5Z1cyd1B0bjJvcTZMaTZjQXd4N1hFKwpaRGxwN3FiRU5YQzZLditwZTJhYjVqcFB2ZDg0RzlDUlNQT2M5SW01SE02OU1Ed3RQanp5c1J4NHhydld0UmZTCmN1SThwdngvUGQxczF1cDJRbjR1ekRNQ2dZQTRuMzZNQm43RUFyaS9pV3l1bGVZYnEwcm9qQTNGWm9FaFlmSEYKcEdiRnZnMlp3VHRmbWx6c0d6Zy9pNGNScEpKdUIwSHd0QWQrUGw2aXpSUjZDbUZ3OElRRU9LUHFVMGJteGlSaQpuQUMzMkVITzVMYzQycWZROTc1N0NQOFBDOC81MktUSDE4bWs3UXhpbU50LzNjV0RhNkVKZmhJQUpYRlBhQm81CmovU1ZuUUtCZ0NoQytmaWhoVVBqZk5NY1FRMitnU25tMktoanZtMUhWUlZYSis3b1pIRnZwN1BnMXNVa1JsTXUKd2VlVXdGd0JLQm9xRWJOTWJ2WTdiZ0NiWnRxbjhEQzUrb1hBdzVvREFaVGpjQ0l3ZGhkUHhTMzAxQzNoMFJtOApiV0JkaWtIc1d2VTllRkp4U2pLRUNIRFhldi9kb2FjRytLU3JBbGdaOTYxd1lyMWkxNHJECi0tLS0tRU5EIFJTQSBQUklWQVRFIEtFWS0tLS0tCg=="
  },
  "gitServer": {
    "pushUsername": "zarf-git-user",
    "pushPassword": "NVd3O1IjfJHTGdQh33D1EBUw",
    "pullUsername": "zarf-git-read-user",
    "pullPassword": "JbpU2L5nJLDIWbeV76lodsFe",
    "address": "http://zarf-gitea-http.zarf.svc.cluster.local:3000",
    "internalServer": true
  },
  "registryInfo": {
    "pushUsername": "zarf-push",
    "pushPassword": "WjMx4wfduHbOz8Pk2UJ5oF56",
    "pullUsername": "zarf-pull",
    "pullPassword": "ahoUV9cOg-bXFBnbNogUdJSg",
    "address": "127.0.0.1:31999",
    "nodePort": 31999,
    "internalRegistry": true,
    "secret": "0VVaqeH2uZwlA0YNWNIz8KPlhaJit4dnvRyXKKPB3VFK98dh"
  },
  "artifactServer": {
    "pushUsername": "zarf-git-user",
    "pushPassword": "",
    "address": "http://zarf-gitea-http.zarf.svc.cluster.local:3000/api/packages/zarf-git-user",
    "internalServer": true
  },
  "loggingSecret": "rkjD7UQpoBqYX8wkp2tHfNAA"
}
```

The initial zarf components ([ZarfInitConfig](https://docs.zarf.dev/docs/create-a-zarf-package/zarf-packages#zarfinitconfig)) will be in the data the `zarf-package-init` secret:

```bash
kubectl get secret -n zarf zarf-package-init  --template='{{.data.data}}' | base64 -d  | jq
```

output

```json
{
  "name": "init",
  "data": {
    "kind": "ZarfInitConfig",
    "metadata": {
      "name": "init",
      "description": "Used to establish a new Zarf cluster",
      "version": "v0.26.4",
      "architecture": "arm64",
      "aggregateChecksum": "1137879a8815937f84327def4b5317e83940305beb6a238b48b8be84f0e5cffc"
    },
    "build": {
      "terminal": "fv-az616-317",
      "user": "runner",
      "architecture": "arm64",
      "timestamp": "Wed, 17 May 2023 02:48:30 +0000",
      "version": "v0.26.4",
      "migrations": [
        "scripts-to-actions",
        "pluralize-set-variable"
      ],
      "differential": false,
      "registryOverrides": {}
    },
    "components": [
      {
        "name": "zarf-injector",
        "description": "Bootstraps a Kubernetes cluster by cloning a running pod in the cluster and hosting the registry image.\nRemoved and destroyed after the Zarf Registry is self-hosting the registry image.\n",
        "required": true,
        "only": {
          "cluster": {}
        },
        "cosignKeyPath": "cosign.pub",
        "import": {
          "path": ""
        },
        "scripts": {},
        "actions": {
          "onCreate": {
            "defaults": {
              "shell": {}
            }
          },
          "onDeploy": {
            "defaults": {
              "shell": {}
            }
          },
          "onRemove": {
            "defaults": {
              "shell": {}
            }
          }
        },
        "files": [
          {
            "source": "sget://defenseunicorns/zarf-injector:arm64-2023-02-09",
            "target": "###ZARF_TEMP###/zarf-injector",
            "executable": true
          }
        ],
        "extensions": {}
      },
      {
        "name": "zarf-seed-registry",
        "description": "Deploys the Zarf Registry using the registry image provided by the Zarf Injector.\n",
        "required": true,
        "only": {
          "cluster": {}
        },
        "import": {
          "path": ""
        },
        "scripts": {},
        "actions": {
          "onCreate": {
            "defaults": {
              "shell": {}
            }
          },
          "onDeploy": {
            "defaults": {
              "shell": {}
            }
          },
          "onRemove": {
            "defaults": {
              "shell": {}
            }
          }
        },
        "charts": [
          {
            "name": "docker-registry",
            "releaseName": "zarf-docker-registry",
            "version": "1.0.0",
            "namespace": "zarf",
            "valuesFiles": [
              "packages/zarf-registry/registry-values.yaml",
              "packages/zarf-registry/registry-values-seed.yaml"
            ],
            "localPath": "packages/zarf-registry/chart"
          }
        ],
        "images": [
          "library/registry:2.8.2"
        ],
        "extensions": {}
      },
      {
        "name": "zarf-registry",
        "description": "Updates the Zarf Registry to use the self-hosted registry image.\nServes as the primary docker registry for the cluster.\n",
        "required": true,
        "only": {
          "cluster": {}
        },
        "import": {
          "path": ""
        },
        "scripts": {},
        "actions": {
          "onCreate": {
            "defaults": {
              "shell": {}
            }
          },
          "onDeploy": {
            "defaults": {
              "shell": {}
            }
          },
          "onRemove": {
            "defaults": {
              "shell": {}
            }
          }
        },
        "charts": [
          {
            "name": "docker-registry",
            "releaseName": "zarf-docker-registry",
            "version": "1.0.0",
            "namespace": "zarf",
            "valuesFiles": [
              "packages/zarf-registry/registry-values.yaml"
            ],
            "localPath": "packages/zarf-registry/chart"
          }
        ],
        "manifests": [
          {
            "name": "registry-connect",
            "namespace": "zarf",
            "files": [
              "packages/zarf-registry/connect.yaml"
            ]
          },
          {
            "name": "kep-1755-registry-annotation",
            "namespace": "zarf",
            "files": [
              "packages/zarf-registry/configmap.yaml"
            ]
          }
        ],
        "images": [
          "library/registry:2.8.2"
        ],
        "extensions": {}
      },
      {
        "name": "zarf-agent",
        "description": "A Kubernetes mutating webhook to enable automated URL rewriting for container\nimages and git repository references in Kubernetes manifests. This prevents\nthe need to manually update URLs from their original sources to the Zarf-managed\ndocker registry and git server.\n",
        "required": true,
        "only": {
          "cluster": {}
        },
        "import": {
          "path": ""
        },
        "scripts": {},
        "actions": {
          "onCreate": {
            "defaults": {
              "shell": {}
            },
            "before": [
              {
                "cmd": "make init-package-local-agent AGENT_IMAGE_TAG=\"v0.26.4\" ARCH=\"arm64\""
              }
            ]
          },
          "onDeploy": {
            "defaults": {
              "shell": {}
            }
          },
          "onRemove": {
            "defaults": {
              "shell": {}
            }
          }
        },
        "manifests": [
          {
            "name": "zarf-agent",
            "namespace": "zarf",
            "files": [
              "packages/zarf-agent/manifests/service.yaml",
              "packages/zarf-agent/manifests/secret.yaml",
              "packages/zarf-agent/manifests/deployment.yaml",
              "packages/zarf-agent/manifests/webhook.yaml"
            ]
          }
        ],
        "images": [
          "ghcr.io/defenseunicorns/zarf/agent:v0.26.4"
        ],
        "extensions": {}
      },
      {
        "name": "logging",
        "description": "Deploys the Promtail Grafana & Loki (PGL) stack.\nAggregates logs from different containers and presents them in a web dashboard.\nRecommended if no other logging stack is deployed in the cluster.\n",
        "only": {
          "cluster": {}
        },
        "import": {
          "path": ""
        },
        "scripts": {},
        "actions": {
          "onCreate": {
            "defaults": {
              "shell": {}
            }
          },
          "onDeploy": {
            "defaults": {
              "shell": {}
            }
          },
          "onRemove": {
            "defaults": {
              "shell": {}
            }
          }
        },
        "charts": [
          {
            "name": "loki-stack",
            "releaseName": "zarf-loki-stack",
            "url": "https://grafana.github.io/helm-charts",
            "version": "2.9.10",
            "namespace": "zarf",
            "valuesFiles": [
              "packages/logging-pgl/pgl-values.yaml"
            ]
          }
        ],
        "manifests": [
          {
            "name": "logging-connect",
            "namespace": "zarf",
            "files": [
              "packages/logging-pgl/connect.yaml"
            ]
          }
        ],
        "images": [
          "docker.io/grafana/promtail:2.7.4",
          "grafana/grafana:8.3.5",
          "grafana/loki:2.6.1",
          "quay.io/kiwigrid/k8s-sidecar:1.19.2"
        ],
        "extensions": {}
      },
      {
        "name": "git-server",
        "description": "Deploys Gitea to provide git repositories for Kubernetes configurations.\nRequired for GitOps deployments if no other git server is available.\n",
        "only": {
          "cluster": {}
        },
        "import": {
          "path": ""
        },
        "scripts": {},
        "actions": {
          "onCreate": {
            "defaults": {
              "shell": {}
            }
          },
          "onDeploy": {
            "defaults": {
              "shell": {}
            },
            "after": [
              {
                "maxTotalSeconds": 60,
                "maxRetries": 3,
                "cmd": "./zarf internal create-read-only-gitea-user"
              },
              {
                "maxTotalSeconds": 60,
                "maxRetries": 3,
                "cmd": "./zarf internal create-artifact-registry-token"
              }
            ]
          },
          "onRemove": {
            "defaults": {
              "shell": {}
            }
          }
        },
        "charts": [
          {
            "name": "gitea",
            "releaseName": "zarf-gitea",
            "url": "https://dl.gitea.io/charts",
            "version": "7.0.4",
            "namespace": "zarf",
            "valuesFiles": [
              "packages/gitea/gitea-values.yaml"
            ]
          }
        ],
        "manifests": [
          {
            "name": "git-connect",
            "namespace": "zarf",
            "files": [
              "packages/gitea/connect.yaml"
            ]
          }
        ],
        "images": [
          "gitea/gitea:1.18.5-rootless"
        ],
        "extensions": {}
      }
    ],
    "variables": [
      {
        "name": "K3S_ARGS",
        "description": "Arguments to pass to K3s",
        "default": "--disable traefik"
      },
      {
        "name": "REGISTRY_EXISTING_PVC",
        "description": "Optional: Use an existing PVC for the registry instead of creating a new one. If this is set, the REGISTRY_PVC_SIZE variable will be ignored."
      },
      {
        "name": "REGISTRY_PVC_SIZE",
        "description": "The size of the persistent volume claim for the registry",
        "default": "20Gi"
      },
      {
        "name": "REGISTRY_PVC_ACCESS_MODE",
        "description": "The access mode of the persistent volume claim for the registry",
        "default": "ReadWriteOnce"
      },
      {
        "name": "REGISTRY_CPU_REQ",
        "description": "The CPU request for the registry",
        "default": "100m"
      },
      {
        "name": "REGISTRY_MEM_REQ",
        "description": "The memory request for the registry",
        "default": "256Mi"
      },
      {
        "name": "REGISTRY_CPU_LIMIT",
        "description": "The CPU limit for the registry",
        "default": "3"
      },
      {
        "name": "REGISTRY_MEM_LIMIT",
        "description": "The memory limit for the registry",
        "default": "2Gi"
      },
      {
        "name": "REGISTRY_HPA_MIN",
        "description": "The minimum number of registry replicas",
        "default": "1"
      },
      {
        "name": "REGISTRY_HPA_MAX",
        "description": "The maximum number of registry replicas",
        "default": "5"
      },
      {
        "name": "REGISTRY_HPA_ENABLE",
        "description": "Enable the Horizontal Pod Autoscaler for the registry",
        "default": "true"
      },
      {
        "name": "GIT_SERVER_EXISTING_PVC",
        "description": "Optional: Use an existing PVC for the git server instead of creating a new one. If this is set, the GIT_SERVER_PVC_SIZE variable will be ignored."
      },
      {
        "name": "GIT_SERVER_PVC_SIZE",
        "description": "The size of the persistent volume claim for git server",
        "default": "10Gi"
      },
      {
        "name": "GIT_SERVER_CPU_REQ",
        "description": "The CPU request for git server",
        "default": "200m"
      },
      {
        "name": "GIT_SERVER_MEM_REQ",
        "description": "The memory request for git server",
        "default": "512Mi"
      },
      {
        "name": "GIT_SERVER_CPU_LIMIT",
        "description": "The CPU limit for git server",
        "default": "3"
      },
      {
        "name": "GIT_SERVER_MEM_LIMIT",
        "description": "The memory limit for git server",
        "default": "2Gi"
      }
    ],
    "constants": [
      {
        "name": "REGISTRY_IMAGE",
        "value": "library/registry"
      },
      {
        "name": "REGISTRY_IMAGE_TAG",
        "value": "2.8.2"
      },
      {
        "name": "AGENT_IMAGE",
        "value": "defenseunicorns/zarf/agent"
      },
      {
        "name": "AGENT_IMAGE_TAG",
        "value": "v0.26.4"
      }
    ]
  },
  "cliVersion": "v0.26.4",
  "deployedComponents": [
    {
      "name": "zarf-injector",
      "installedCharts": null
    },
    {
      "name": "zarf-seed-registry",
      "installedCharts": [
        {
          "namespace": "zarf",
          "chartName": "zarf-docker-registry"
        }
      ]
    },
    {
      "name": "zarf-registry",
      "installedCharts": [
        {
          "namespace": "zarf",
          "chartName": "zarf-docker-registry"
        },
        {
          "namespace": "zarf",
          "chartName": "zarf-a0e2de5862bbc49ea7f205abbb4da84041fe9c74"
        },
        {
          "namespace": "zarf",
          "chartName": "zarf-6fd4933a3193a9565e76c479531ec18fbae1b512"
        }
      ]
    },
    {
      "name": "zarf-agent",
      "installedCharts": [
        {
          "namespace": "zarf",
          "chartName": "zarf-d2db14ef40305397791454e883b26fc94ad9615d"
        }
      ]
    }
  ],
  "connectStrings": {
    "registry": {
      "description": "Internal Zarf Registry (run zarf tools registry login to authenticate)",
      "url": "/v2/_catalog"
    }
  }
}
```

You will see configmaps `zarf-payload-xxx`, which are partial OCI images of the deployed packages.

```bash
kubectl get cm -n zarf
```

output

```bash
NAME               DATA   AGE
kube-root-ca.crt   1      7m51s
rust-binary        1      7m48s
zarf-payload-000   1      7m48s
zarf-payload-001   1      7m47s
zarf-payload-002   1      7m47s
zarf-payload-003   1      7m47s
zarf-payload-004   1      7m46s
zarf-payload-005   1      7m46s
zarf-payload-006   1      7m46s
zarf-payload-007   1      7m45s
zarf-payload-008   1      7m45s
zarf-payload-009   1      7m45s
zarf-payload-010   1      7m44s
zarf-payload-011   1      7m44s
```

To read more about the internals of zarf, checkout the [Nerd Notes](https://docs.zarf.dev/docs/contribute-to-zarf/nerd-notes).  

## Deploy Helm Chart with Zarf

To create a zarf package, you must create a `ZarfPackageConfig`.

```yaml
cat << EOF > hello-zarf-chart/zarf.yaml
kind: ZarfPackageConfig
metadata:
  name: helm-chart
  description: |
    A Zarf package that deploys a helm chart
  version: 0.0.1

components:
  - name: hello-zarf-chart
    required: true
    charts:
      # Must match name in Chart.yaml
      - name: hello-zarf-chart
      # Must match version in Chart.yaml
        version: 0.1.0
        namespace: default
        localPath: .
    # Must include images in helm chart
    images:
      - docker.io/cmwylie19/hello-zarf
      - busybox      
EOF
```

We MUST have correspoding names, versions, and images from the helm chart's `Chart.yaml` file, and define the images in `ZarfPackageConfig`.

Create the zarf package. (Press enter twice at the prompts to create the package and use the default of 0 for "Maximum Package Size")

```bash
zarf package create hello-zarf-chart
```

output 

```bash
Saving log file to
/var/folders/v0/slmrzc4s6kx4n7jb77ch9fc80000gn/T/zarf-2023-06-07-18-12-58-3447967329.log

Using build directory hello-zarf-chart

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

kind: ZarfPackageConfig
metadata:
  name: helm-chart
  description: |
    A Zarf package that deploys a helm chart
  version: 0.0.1
components:
- name: hello-zarf-chart
  required: true
  charts:
  - name: hello-zarf-chart
    version: 0.1.0
    namespace: default
    localPath: .
  images:
  - docker.io/cmwylie19/hello-zarf
  - busybox

? Create this Zarf package? Yes

Specify a maximum file size for this package in Megabytes. Above this size, the package will be
split into multiple files. 0 will disable this feature.
? Please provide a value for "Maximum Package Size" 0

                                                                                       
  📦 HELLO-ZARF-CHART COMPONENT                                                        
                                                                                       

  ✔  Processing helm chart hello-zarf-chart:0.1.0 from .                                                               

                                                                                       
  📦 COMPONENT IMAGES                                                                  
                                                                                       

  ✔  Loading metadata for 2 images.                                                                                    
  ✔  Pulling 2 images (5.80 MBs)                                                                                       
  ✔  Creating SBOMs for 2 images and 0 components with files.
```

This creates a compressed zarf package in the root directory that containing all of the bundled manifests and images: `zarf-package-helm-chart-[arch]-0.0.1.tar.zst`.  


Deploy the zarf package in the cluster with `zarf package deploy`, [Press Tab] to find the correct artifact, then (y) to deploy.

```bash
zarf package deploy
```

output
```bash
Saving log file to
/var/folders/v0/slmrzc4s6kx4n7jb77ch9fc80000gn/T/zarf-2023-06-08-08-24-11-1716764624.log
? Choose or type the package file zarf-package-helm-chart-arm64-0.0.1.tar.zst

  ✔  All of the checksums matched!                                                                                     
  ✔  Loading Zarf Package zarf-package-helm-chart-arm64-0.0.1.tar.zst                                                  

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

kind: ZarfPackageConfig
metadata:
  name: helm-chart
  description: |
    A Zarf package that deploys a helm chart
  version: 0.0.1
  architecture: arm64
  aggregateChecksum: 4c7ad2aeb4a75dcdef62862cad89a7b20f5a09fd632b082aff7ab6c57d99455c
build:
  terminal: Cases-MacBook-Pro.local
  user: cmwylie19
  architecture: arm64
  timestamp: Wed, 07 Jun 2023 18:13:04 -0400
  version: v0.26.4
  migrations:
  - scripts-to-actions
  - pluralize-set-variable
  differential: false
  registryOverrides: {}
components:
- name: hello-zarf-chart
  required: true
  charts:
  - name: hello-zarf-chart
    version: 0.1.0
    namespace: default
    localPath: .
  images:
  - docker.io/cmwylie19/hello-zarf
  - busybox

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This package has 2 artifacts with software bill-of-materials (SBOM) included. You can view them now
in the zarf-sbom folder in this directory or to go directly to one, open this in your browser:
/Users/cmwylie19/hello-zarf/zarf-sbom/sbom-viewer-busybox.html

* This directory will be removed after package deployment.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

? Deploy this Zarf package? (y/N) 
```


Wait for the app to be ready

```bash
kubectl wait pod --for=condition=Ready -l app=hello-zarf --timeout=180s -n webserver
```

Check pod and service are running.   

```bash
kubectl get svc,po -n webserver -l app=hello-zarf
```

output
```bash
NAME                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/hello-zarf   ClusterIP   10.96.125.229   <none>        8081/TCP   32s

NAME                             READY   STATUS    RESTARTS   AGE
pod/hello-zarf-c558dd559-6zhtt   1/1     Running   0          32s
```


Curl against service to ensure app is working.   

```bash
kubectl run curler --image=nginx:alpine --rm -it --restart=Never  -- curl hello-zarf.webserver.svc.cluster.local:8081/hi
```

output
```bash 
Let's kick Zarf's tires!🦄pod "curler" deleted
```

Clean up the manual deployment,svc,and pod

```bash
kubectl delete deploy,svc,po -l app=hello-zarf -n webserver --force --grace-period=0

kubectl delete ns webserver
```

## Deploy Kubernetes manifests with Zarf

We create a new `ZarfPackageConfig` to package and deploy manifests.

We MUST define images and files for kubernetes manifests in the images and manifests sections of `ZarfPackageConfig`.

Create the zarf package. (Press enter twice at the prompts to create the package and use the default of 0 for "Maximum Package Size")

```yaml
cat << EOF > k8s/zarf.yaml
kind: ZarfPackageConfig
metadata:
  name: k8s-manifests
  description: |
    A Zarf package that deploys kubernetes manifests
  version: 0.0.1
components:
  - name: k8s-folder
    description: Does a kubectl create -f on the k8s folder
    # prompt the user to create package?
    required: true
    # new
    manifests:
      - name: k8s-folder
        namespace: webserver
        # webserver deployment, svc
        files:
          - zarf-practice.yaml
    # required to tell zarf where your image lives
    images:
      - docker.io/cmwylie19/hello-zarf
EOF
```


Create the zarf package by poiting zarf to `k8s/zarf.yaml`. (Press y to create the package and "Maximum Package Size" 0 or press enter )

```bash
zarf package create k8s
```

output
```bash
Saving log file to
/var/folders/v0/slmrzc4s6kx4n7jb77ch9fc80000gn/T/zarf-2023-06-08-08-36-41-3715853135.log

Using build directory k8s

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

kind: ZarfPackageConfig
metadata:
  name: k8s-manifests
  description: |
    A Zarf package that deploys kubernetes manifests
  version: 0.0.1
components:
- name: k8s-folder
  description: Does a kubectl create -f on the k8s folder
  required: true
  manifests:
  - name: k8s-folder
    namespace: webserver
    files:
    - zarf-practice.yaml
  images:
  - docker.io/cmwylie19/hello-zarf

? Create this Zarf package? Yes

Specify a maximum file size for this package in Megabytes. Above this size, the package will be
split into multiple files. 0 will disable this feature.
? Please provide a value for "Maximum Package Size" 0

                                                                                       
  📦 K8S-FOLDER COMPONENT                                                              
                                                                                       

  ✔  Loading 1 K8s manifests                                                                                                                                     

                                                                                       
  📦 COMPONENT IMAGES                                                                  
                                                                                       

  ✔  Loading metadata for 1 images.                                                                                                                              
  ✔  Pulling 1 images (3.80 MBs)                                                                                                                                 
  ✔  Creating SBOMs for 1 images and 0 components with files.  
```

Deploy the zarf package [Press Tab], select the `zarf-package-k8s-manifests-*-0.0.1.tar.zst`, then (y)

```bash
zarf package deploy
```

output

```bash

Saving log file to
? Choose or type the package file zarf-package-k8s-manifests-arm64-0.0.1.tar.zst

  ✔  All of the checksums matched!                                                                                            
  ✔  Loading Zarf Package zarf-package-k8s-manifests-arm64-0.0.1.tar.zst                                                      

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

kind: ZarfPackageConfig
metadata:
  name: k8s-manifests
  description: |
    A Zarf package that deploys kubernetes manifests
  version: 0.0.1
  architecture: arm64
  aggregateChecksum: efb8c3270eae3dc9fc1053c9146284fc37abcd6ef3f2e7aa422b74f3c6b5144a
build:
  terminal: Cases-MacBook-Pro.local
  user: cmwylie19
  architecture: arm64
  timestamp: Thu, 08 Jun 2023 09:39:07 -0400
  version: v0.26.4
  migrations:
  - scripts-to-actions
  - pluralize-set-variable
  differential: false
  registryOverrides: {}
components:
- name: k8s-folder
  description: Does a kubectl create -f on the k8s folder
  required: true
  manifests:
  - name: k8s-folder
    namespace: webserver
    files:
    - zarf-practice.yaml
  images:
  - docker.io/cmwylie19/hello-zarf

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This package has 1 artifacts with software bill-of-materials (SBOM) included. You can view them now
in the zarf-sbom folder in this directory or to go directly to one, open this in your browser:
/Users/cmwylie19/hello-zarf/zarf-sbom/sbom-viewer-docker.io_cmwylie19_hello-zarf.html

* This directory will be removed after package deployment.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

? Deploy this Zarf package? Yes

                                                                                       
  📦 K8S-FOLDER COMPONENT                                                              
                                                                                       

  ✔  Waiting for cluster connection (30s timeout)                                                                             
  ✔  Loading the Zarf State from the Kubernetes cluster                                                                       
  ✔  Pushed 1 images to the zarf registry                                                                                     
  ✔  Starting helm chart generation k8s-folder                                                                                
  ✔  Processing helm chart raw-k8s-manifests-k8s-folder-k8s-folder:0.1.1686231570 from Zarf-generated helm chart              
  ✔  Zarf deployment complete

```



Wait for the app to be ready

```bash
kubectl wait pod --for=condition=Ready -l app=hello-zarf --timeout=180s -n webserver
```

Check pod and service are running.   

```bash
kubectl get svc,po -n webserver -l app=hello-zarf
```

output
```bash
NAME                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/hello-zarf   ClusterIP   10.96.125.229   <none>        8081/TCP   32s

NAME                             READY   STATUS    RESTARTS   AGE
pod/hello-zarf-c558dd559-6zhtt   1/1     Running   0          32s
```


Curl against service to ensure app is working.   

```bash
kubectl run curler --image=nginx:alpine --rm -it --restart=Never  -- curl hello-zarf.webserver.svc.cluster.local:8081/hi
```

output
```bash 
Let's kick Zarf's tires!🦄pod "curler" deleted
```

Clean up the manual deployment,svc,and pod

```bash
kubectl delete deploy,svc,po -l app=hello-zarf -n webserver --force --grace-period=0

kubectl delete ns webserver
```

This is only scratching the capability of zarf, there are hooks, actions and more features not listed in this initial tutorial. Go to [zarf.dev](https://zarf.dev) to read more.

# Cleanup

```bash
kind delete cluster --name=zarf
```

[TOP](#hello-zarf-tutorial)
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
- [jq](https://jqlang.github.io/jq/download/)

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

```bashß
# output
NAME                    TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/hello-zarf   ClusterIP   10.96.191.232   <none>        8081/TCP   5s

NAME                                 READY   STATUS    RESTARTS   AGE
pod/hello-zarf-7dd8746449-x8m7r   1/1     Running   0          5s
```

Curl against service to ensure app is working.   

```bash
kubectl run curler --image=nginx:alpine --rm -it --restart=Never  -- curl hello-zarf.webserver.svc.cluster.local:8081/hi
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

Running `zarf init` installs Zarf onto the target cluster.

```bash
zarf init 
```

After `zarf init` you will see an image registry pod in the zarf namespace, used to store images packed images  which are later saved in the final compressed tarball  (similar to a `docker save <image repo>/<user>/<container> -o <container>.tar`). There will be two replicas of the `agent-hook`, a mutating webhook that renames the images from the previous image registry like docker.io to the internal image registry deployed in the namespace. 

```bash
kubectl get po -n zarf
```

You will also see a `zarf-state` secret which  contains the credentials for components Zarf uses.

```bash
kubectl get secret zarf-state -n zarf --template='{{.data.state}}' | base64 -d  | jq
```

The initial zarf components ([ZarfInitConfig](https://docs.zarf.dev/docs/create-a-zarf-package/zarf-packages#zarfinitconfig)) will be in the data the `zarf-package-init` secret:

```bash
kubectl get secret -n zarf zarf-package-init  --template='{{.data.data}}' | base64 -d  | jq
```

You will see configmaps `zarf-payload-xxx`, which are partial OCI images of the deployed packages.


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

Notice, we MUST have correspoding names, and images from the helm chart's `Chart.yaml`, and clearly define the images in `ZarfPackageConfig`.

Create the zarf package. (Press enter twice at the prompts to create the package and use the default of 0 for "Maximum Package Size")

```bash
zarf package create hello-zarf-chart

# output 
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

# output

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
# output
NAME                    TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/hello-zarf   ClusterIP   10.96.191.232   <none>        8081/TCP   5s

NAME                                 READY   STATUS    RESTARTS   AGE
pod/hello-zarf-7dd8746449-x8m7r   1/1     Running   0          5s
```


Curl against service to ensure app is working.   

```bash
kubectl run curler --image=nginx:alpine --rm -it --restart=Never  -- curl hello-zarf.webserver.svc.cluster.local:8081/hi
#output 
Let's kick Zarf's tires!🦄pod "curler" deleted
```

Clean up the manual deployment,svc,and pod

```bash
kubectl delete deploy,svc,po -l app=hello-zarf -n webserver --force --grace-period=0

kubectl delete ns webserver
```

## Deploy Kubernetes manifests with Zarf

We create a new ZarfPackageConfig to deploy the manifests. _Notice the structure is not quite as rigid when deploying manifests as there is no need for matching versions._

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
    manifests:
      - name: k8s-folder
        namespace: webserver
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

# output
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

Deploy the zarf package [Press Tab], then (y)

```bash
zarf package deploy

# output


# Cleanup

```bash
kind delete cluster --name=zarf
```

[TOP](#hello-zarf-tutorial)
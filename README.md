# Hello Zarf Tutorial

_This repo contains a basic webserver to be deployed by [Zarf](https://github.com/defenseunicorns/zarf.git). The webserver has a `k8s` folder with Kubernetes manifests and a `hello-zarf-chart` folder with a helm chart. The first step is to spin up a Kind cluster and initialize Zarf._

**TOC**
- [Prerequisites](#prerequisites)
- [Create Cluster](#create-cluster)
- [Deploy without Zarf](#deploy-webserver-without-zarf)
- [Deploy with Zarf through Helm](#deploy-with-zarf-through-helm)
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
 
```bash
kubectl create -f k8s/
sleep 2
kubectl wait pod --for=condition=Ready -l app=hello-zarf --timeout=180s -n webserver
```

Ensure pod,svc are running.   

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


## Deploy with Zarf through Helm

To create a zarf package, you must create a `ZarfPackageConfig`.

```yaml
cat << EOF > zarf.yaml
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
EOF
```
```bash
zarf package create hello-zarf-chart
```

# Cleanup

```bash
kind delete cluster --name=zarf
```
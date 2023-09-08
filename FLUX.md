Install

```bash
kubectl create -f https://github.com/fluxcd/flux2/releases/latest/download/install.yaml
```

```yaml
kubectl create -f -<<EOF
apiVersion: source.toolkit.fluxcd.io/v1
kind: OCIRepository
metadata:
  name: hello-zarfs
  namespace: flux-system
spec:
  interval: 10m
  url: oci://docker.io/cmwylie19/oci-manifests-hello-zarf
  ref:
    tag: latest
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: hello-zarf
  namespace: flux-system
spec:
  interval: 10m
  targetNamespace: webserver
  prune: true
  sourceRef:
    kind: OCIRepository
    name: hello-zarf
  path: ./
EOF
```

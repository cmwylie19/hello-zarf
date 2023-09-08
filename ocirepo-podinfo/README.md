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


--- 

Raw Admission Request

```bash
{"apiVersion":"source.toolkit.fluxcd.io/v1beta2","kind":"OCIRepository","metadata":{"annotations":{"meta.helm.sh/release-name":"zarf-1ac628beb6600ac961cf019ef1e52045b7fcbb0a","meta.helm.sh/release-namespace":"flux-system"},"creationTimestamp":"2023-09-05T18:23:12Z","deletionGracePeriodSeconds":0,"deletionTimestamp":"2023-09-05T18:26:10Z","generation":2,"labels":{"app.kubernetes.io/managed-by":"Helm"},"managedFields":[{"apiVersion":"source.toolkit.fluxcd.io/v1beta2","fieldsType":"FieldsV1","fieldsV1":{"f:metadata":{"f:annotations":{".":{},"f:meta.helm.sh/release-name":{},"f:meta.helm.sh/release-namespace":{}},"f:labels":{".":{},"f:app.kubernetes.io/managed-by":{}}},"f:spec":{".":{},"f:interval":{},"f:provider":{},"f:ref":{".":{},"f:tag":{}},"f:timeout":{},"f:url":{}}},"manager":"zarf-mac-apple","operation":"Update","time":"2023-09-05T18:23:12Z"},{"apiVersion":"source.toolkit.fluxcd.io/v1beta2","fieldsType":"FieldsV1","fieldsV1":{"f:status":{"f:conditions":{},"f:observedGeneration":{},"f:url":{}}},"manager":"source-controller","operation":"Update","subresource":"status","time":"2023-09-05T18:26:10Z"}],"name":"hello-zarf","namespace":"flux-system","resourceVersion":"12657","uid":"a60a6139-9ac6-4e1d-b21c-16a24f2c1557"},"spec":{"interval":"10m","provider":"generic","ref":{"tag":"latest"},"secretRef":{"name":"private-git-server"},"timeout":"60s","url":"oci://docker.io/cmwylie19/oci-manifests-hello-zarf"},"status":{"conditions":[{"lastTransitionTime":"2023-09-05T18:23:13Z","message":"stored artifact for digest 'a4987468b3a828748d4df69afc207a08c038ea23e9dae989e7bba2e7e1d0a7c3'","observedGeneration":2,"reason":"Succeeded","status":"True","type":"Ready"},{"lastTransitionTime":"2023-09-05T18:23:13Z","message":"stored artifact for digest 'a4987468b3a828748d4df69afc207a08c038ea23e9dae989e7bba2e7e1d0a7c3'","observedGeneration":1,"reason":"Succeeded","status":"True","type":"ArtifactInStorage"}],"observedGeneration":2,"url":"http://source-controller.flux-system.svc.cluster.local./ocirepository/flux-system/hello-zarf/latest.tar.gz"}}
```

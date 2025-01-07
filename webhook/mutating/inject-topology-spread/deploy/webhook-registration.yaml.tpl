apiVersion: admissionregistration.k8s.io/v1
kind: MutatingWebhookConfiguration
metadata:
  name: inject-topology-spread
  labels:
    app: inject-topology-spread
    kind: mutator
webhooks:
  - name: inject-topology-spread.k8s.io
    admissionReviewVersions:
    - v1
    - v1beta1
    clientConfig:
      service:
        name: inject-topology-spread-webhook
        namespace: default
        path: "/mutate"
      caBundle: CA_BUNDLE
    rules:
      - operations: [ "CREATE" ]
        apiGroups: [""]
        apiVersions: ["v1"]
        resources: ["pods"]
    namespaceSelector:
      matchLabels:
        kubernetes.io/metadata.name: demo
    sideEffects: None
        
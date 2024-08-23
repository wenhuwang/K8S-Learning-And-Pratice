apiVersion: admissionregistration.k8s.io/v1
kind: MutatingWebhookConfiguration
metadata:
  name: pod-annotate-webhook
  labels:
    app: pod-annotate-webhook
    kind: mutator
webhooks:
  - name: pod-annotate-webhook.slok.dev
    admissionReviewVersions:
    - v1
    - v1beta1
    clientConfig:
      service:
        name: pod-annotate-webhook
        namespace: default
        path: "/mutate"
      caBundle: CA_BUNDLE
    rules:
      - operations: [ "CREATE" ]
        apiGroups: ["apps"]
        apiVersions: ["v1"]
        resources: ["deployments"]
    namespaceSelector:
      matchLabels:
        kubernetes.io/metadata.name: demo
    sideEffects: None
        
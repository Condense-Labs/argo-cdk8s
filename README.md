# ArgoCD with cdk8s

This repo publishes a Docker image that allows you to use [`cdk8s`](https://cdk8s.io/)
as a [Config Management Plugin](https://argo-cd.readthedocs.io/en/stable/operator-manual/config-management-plugins/) (CMP) with ArgoCD.

This makes it possible to have Argo execute cdk8s to build your resources
directly. This goes slightly contrary to the immutability of GitOps, as well
as ArgoCD's own guidance to push to a separate repository. That said, it's
very convenient, and saves a lot of administrative hassle for smaller orgs.

## Usage/installation

To use this CMP, you need to add a sidecar and configure the cmp `ConfigMap`.
You can do this using the official helm chart, with a `values.yaml` like this:

```yaml
repoServer:
  extraContainers:
    - name: cmp-cdk8s
      securityContext:
        runAsNonRoot: true
        runAsUser: 999     # This is the ArgoCD user; the Dockerfile uses a named ID which k8s doesn't recognise
      image: ghcr.io/condense-labs/argocd:v2.8.2
      imagePullPolicy: IfNotPresent
      command: [/var/run/argocd/argocd-cmp-server]
      volumeMounts:
        - name:  var-files
          mountPath: /var/run/argocd
        - name: plugins
          mountPath: /home/argocd/cmp-server/plugins
        - name: cmp-config
          subPath: cdk8s.yaml
          mountPath: /home/argocd/cmp-server/config/plugin.yaml
        - name: cmp-tmp
          mountPath: /tmp
  volumes:
    - name: cmp-config
      configMap:
        name: argocd-cmp-cm
    - emptyDir: {}
      name: cmp-tmp
configs:
  cmp:
    create: true
    plugins:
      cdk8s:                           # This will write a cdk8s.yaml file
        init:                          # Install the dependencies and build the yaml
          command: ["bash"]
          args: ["-c", "echo 'Initializing...' && npm ci && npm run build"]
        generate:                      # Concatenate all the yaml
          command: ["bash"]
          args: ["-c", 'directory="dist"; separator="---"; for file in "$directory"/*; do cat "$file"; echo "$separator"; done']
        discover:
          find:
            glob: "**/cdk8s.yaml"
```

If you need access to additional environment variables in `cdk8s`, you can add them to
the CMP container. A useful variable might be `APP_ENV`, to let you distinguish between
target environments (if you're not using a management cluster).

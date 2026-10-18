# Go Web App on AWS EKS: Troubleshooting Notes

This guide records deployment issues, causes, fixes, verification steps, and lessons learned while deploying the Go web app with Docker Hub, GitHub Actions, Helm, Kubernetes, AWS EKS, and Argo CD.

## Project details

- Repository: https://github.com/dugutarithish/web-app
- Argo CD Application: go-web-app in namespace argocd
- Helm chart: helm/go-web-app-chart
- Kubernetes workload namespace: default
- Image verified during troubleshooting: rithishkumar/go-web-app:root-fix
- Domain tested: http://www.rithish.co.in/

## Deployment workflow

1. Source code is maintained in GitHub.
2. GitHub Actions builds and tests the Go app, runs linting, and publishes a Docker image to Docker Hub.
3. Helm values and templates describe the Kubernetes deployment.
4. Argo CD watches Git and reconciles the desired configuration with the cluster.
5. NGINX Ingress routes external HTTP traffic to the Kubernetes Service and Pods.

## Problems and solutions

### 1. Homepage returned HTTP 404

**Symptom:** The root path / returned 404 page not found, although other routes had responded.

**Cause:** The running image was an older build that did not serve the root route as intended.

**Fix:** Updated the Go application so / serves the homepage, built and pushed rithishkumar/go-web-app:root-fix, updated the Helm image tag in Git, and deployed through Argo CD.

**Verification:** The request to http://www.rithish.co.in/ returned HTTP 200 OK and homepage HTML during the troubleshooting session.

~~~bash
kubectl port-forward deployment/go-web-app 8081:8080
curl -i http://localhost:8081/
curl -i http://www.rithish.co.in/
~~~

### 2. Kubernetes continued using the old image

**Symptom:** The Deployment still referenced rithishkumar/go-web-app:38916173218 after a corrected image had been published.

**Cause:** helm/go-web-app-chart/values.yaml still specified the old image.tag.

**Fix:** Set the chart image tag to root-fix, commit and push the change, then refresh and sync the Argo CD Application.

**Verification:** The live Deployment image was rithishkumar/go-web-app:root-fix.

~~~bash
# Run from the Helm chart directory
cat values.yaml
helm template go-web-app . | grep 'image:'

kubectl get deployment go-web-app -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
kubectl rollout status deployment/go-web-app
~~~

### 3. Argo CD showed OutOfSync after a successful sync

**Symptom:** The sync operation succeeded, but the Application still showed OutOfSync.

**Cause:** An obsolete Ingress remained in the cluster after it was removed from the current chart. Automated pruning was disabled.

**Fix:** Inspected the Application and Ingress resources, confirmed rithish-co-in was the intended Ingress, and removed only the obsolete go-web-app Ingress after checking the intended route.

**Verification:** Argo CD subsequently reported Synced and Healthy.

~~~bash
kubectl get application go-web-app -n argocd
kubectl describe application go-web-app -n argocd
kubectl get ingress -n default

# Only run after confirming this is the obsolete resource
kubectl delete ingress go-web-app -n default
kubectl get application go-web-app -n argocd
~~~

### 4. Manual Kubernetes changes did not persist

**Symptom:** A manual change to the live Deployment image was not a durable fix and could be reverted.

**Cause:** Argo CD automated sync and self-healing were enabled, with Git as the source of truth.

**Fix:** Changed the image tag in the Helm values file in Git, then allowed Argo CD to reconcile the Deployment.

**Lesson:** Live commands are useful for diagnosis and temporary tests. Make permanent configuration changes in Git.

### 5. Two Ingress resources used the same hostname

**Symptom:** Both go-web-app and rithish-co-in appeared for www.rithish.co.in.

**Cause:** The obsolete Ingress remained after the intended Ingress resource was introduced.

**Fix:** Confirmed the intended NGINX Ingress and removed the old resource.

~~~bash
kubectl get ingress -n default

# Only after confirming the old resource is obsolete
kubectl delete ingress go-web-app -n default
~~~

### 6. Ingress routing needed consistent configuration

**Symptom:** The earlier Helm Ingress template lacked an explicit Ingress class and had a rewrite annotation that was not needed for the intended route.

**Fix:** Set ingressClassName to nginx, configured host www.rithish.co.in and path / with Prefix behavior, routed traffic to Service go-web-app on port 80, and kept the Service as ClusterIP targeting container port 8080.

**Verification:** The configured Ingress showed the NGINX class and the public homepage returned HTTP 200 during testing.

~~~bash
# Run from the Helm chart directory
helm template go-web-app .
kubectl get ingress -n default
~~~

### 7. Git, local Helm output, and live configuration were misaligned

**Symptom:** Local rendered output and the live Deployment initially showed the old image tag.

**Cause:** The committed Helm values still selected the old tag. Argo CD was deploying the configuration stored in Git.

**Fix:** Inspected the values and rendered manifests, committed the corrected image tag, refreshed Argo CD, and synced the intended revision.

~~~bash
# Run from the Helm chart directory
helm template go-web-app . | grep 'image:'

kubectl annotate application go-web-app -n argocd argocd.argoproj.io/refresh=hard --overwrite
kubectl get application go-web-app -n argocd
kubectl describe application go-web-app -n argocd
~~~

During the recorded verification, the revision was 3c47247873c43f5e91b4ac963e7e914921a8b1e5, the image tag was root-fix, and sync succeeded. This is historical evidence, not a value to hard-code for future deployments.

## Useful verification checklist

~~~bash
kubectl get application go-web-app -n argocd
kubectl describe application go-web-app -n argocd
kubectl get deployment go-web-app -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
kubectl rollout status deployment/go-web-app
kubectl get ingress -n default
curl -i http://www.rithish.co.in/
~~~

## Outcome recorded during troubleshooting

- Deployment used rithishkumar/go-web-app:root-fix.
- Kubernetes rollout completed successfully.
- Homepage returned HTTP 200 OK.
- The obsolete Ingress was removed.
- Argo CD reported Synced and Healthy.

These are results from the documented troubleshooting session. Re-run the checks to confirm the current state.

## Remaining improvement: HTTPS

HTTPS/TLS was not confirmed as configured for the custom domain during the troubleshooting session, and a browser screenshot showed a Not secure indicator for the AWS load-balancer URL. Configure and verify a valid certificate and an appropriate Ingress/load-balancer TLS setup before describing the public endpoint as secure.

## Lessons learned

- In GitOps, Git is the source of truth. Make durable configuration changes in Git, not only in live Kubernetes resources.
- A successful Argo CD sync does not guarantee the intended image tag was selected.
- Use helm template to inspect rendered configuration before syncing.
- Investigate OutOfSync by checking the resource tree and sync result; stale resources may remain when pruning is disabled.
- Verify each layer independently: image tag, Deployment rollout, Service, Ingress, HTTP response, and Argo CD health.

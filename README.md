# Go Web App | Docker, Kubernetes, Helm & GitOps with Argo CD

A simple Go web application that serves a multi-page DevOps learning website. This repository packages the app with Docker, includes Kubernetes manifests and a Helm chart, and uses GitHub Actions for build, test, lint, and container-image publishing. Argo CD is used to track the Kubernetes application through GitOps.

**Live website:** http://rithish.co.in  
**Repository:** https://github.com/dugutarithish/web-app

> The public website and cluster endpoints can change or be unavailable. The screenshots below document the state captured during deployment.

## Screenshots

### Website home page
![Website home page](docs/images/home-page.png)

### Courses page
![Courses page](docs/images/courses-page.png)

### About page
![About page](docs/images/about-page.png)

### Contact page
![Contact page](docs/images/contact-page.png)

### Argo CD application health and sync status
![Argo CD application showing Healthy and Synced](docs/images/argocd-application.png)

## Architecture

```text
Source code (GitHub)
        |
        v
GitHub Actions CI
  |-- Build Go application
  |-- Run Go tests
  |-- Run golangci-lint
  `-- Build and push Docker image to Docker Hub
        |
        v
Helm chart / Kubernetes manifests in Git
        |
        v
Argo CD watches Git and synchronizes the application
        |
        v
Kubernetes Deployment -> Pods -> Service -> Ingress
        |
        v
https://rithish.co.in
```

## Technology stack

- **Go** — HTTP server and route handlers for Home, Courses, About, and Contact pages.
- **Docker** — multi-stage container image build.
- **GitHub Actions** — build, test, lint, and image-publishing workflow.
- **Docker Hub** — container image registry (`rithishkumar/go-web-app`).
- **Kubernetes** — Deployment, Service, and Ingress manifests.
- **Helm** — chart templates and configurable deployment values.
- **Argo CD** — GitOps delivery and application sync/health visibility.
- **Nginx Ingress Controller** — HTTP routing for the configured host.

## Repository layout

```text
.
├── .github/
│   └── workflows/
│       └── ci.yaml                # Build, test, lint, and image publishing
├── go-web-app/
│   ├── Dockerfile                 # Multi-stage Go image build
│   ├── go.mod
│   ├── main.go                    # HTTP routes and server
│   ├── main_test.go               # Go tests
│   └── static/                    # HTML pages and static assets
├── k8s/
│   └── manifests/
│       ├── deployment.yaml
│       ├── service.yaml
│       └── ingress.yaml
├── helm/
│   └── go-web-app-chart/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
└── gitops/
    └── argocd/                    # Argo CD setup notes
```

## Application pages

The Go server listens on port `8080` and serves these routes:

| Route | Page |
|---|---|
| `/` or `/home` | Home |
| `/courses` | Courses and learning resources |
| `/about` | About the author |
| `/contact` | Contact information |

## Run locally

Prerequisites: Go 1.22 or a compatible Go toolchain.

```bash
git clone https://github.com/dugutarithish/web-app.git
cd web-app/go-web-app
go test ./...
go run .
```

Open `http://localhost:8080` in your browser.

## Build and run with Docker

From the repository root:

```bash
docker build -t go-web-app:local ./go-web-app
docker run --rm -p 8080:8080 go-web-app:local
```

Then open `http://localhost:8080`.

## Kubernetes deployment

The repository includes example Kubernetes manifests. Review the image tag and ingress host before applying them to your cluster.

```bash
kubectl apply -f k8s/manifests/
kubectl get deployments,pods,services,ingress
```

The Ingress manifest is configured for `www.rithish.co.in` and the Nginx Ingress class. Make sure DNS points to your Ingress endpoint and the controller is installed before expecting the hostname to work.

## Deploy with Helm

Validate and render the chart before installing:

```bash
helm lint ./helm/go-web-app-chart
helm template go-web-app ./helm/go-web-app-chart
```

To install or upgrade it in a cluster:

```bash
helm upgrade --install go-web-app ./helm/go-web-app-chart \
  --namespace default
```

Review `helm/go-web-app-chart/values.yaml` first. In particular, confirm the desired image repository/tag and enable/configure Ingress for your environment.

## CI/CD workflow

The workflow in `.github/workflows/ci.yaml` runs on pushes to `main` (with configured path exclusions). It builds the Go application, runs tests and linting, then builds and publishes a Docker image to Docker Hub. The workflow also contains a step to update the Helm chart image tag in Git.

Configure the required repository secrets in GitHub Actions before running the image-publishing steps:

- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`
- `TOKEN` (a token with permission to push the chart update commit)

**Important:** Before relying on automated image-tag updates, verify that the workflow writes the intended value from the actual image tag produced by that run. The tag-update command should not use a hard-coded or stale tag.

## GitOps with Argo CD

Argo CD monitors the declared application source and reports synchronization and health. The screenshot above shows the `go-web-app` application in a **Healthy** and **Synced** state at the time it was captured. For your own cluster, make sure the Argo CD Application points to this repository, the correct branch/path, and the target Kubernetes namespace.

Argo CD installation notes are available in [`gitops/argocd/install.md`](gitops/argocd/install.md).

## What I practised

- Building a small HTTP application in Go.
- Packaging an application into a Docker image.
- Automating Go build, test, lint, and image-publishing steps with GitHub Actions.
- Describing an app deployment using Kubernetes manifests and Helm.
- Using Argo CD to monitor synchronization and application health.
- Routing application traffic through Kubernetes Service and Ingress resources.

## Future improvements

- Add HTTPS/TLS and redirect HTTP traffic to HTTPS.
- Use a single source of truth for image tags across CI, Helm, Kubernetes, and Argo CD.
- Add health/readiness probes and resource requests/limits to the Kubernetes workload.
- Add workflow status badges and document a reproducible cluster setup.

## License

See the [`go-web-app/LICENSE`](go-web-app/LICENSE) file.

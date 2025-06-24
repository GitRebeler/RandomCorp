# PowerShell script to deploy Random Corp application to LKE using Helm and Flux
# This creates the necessary Kubernetes manifests and Helm charts

param(
    [string]$GitHubUser = "GitRebeler",  # Change this!
    [string]$GitHubRepo = "RandomCorp",
    [string]$Registry = "docker.io/johnhebeler"  # e.g., "docker.io/yourusername"
)

Write-Host "=== Setting up Random Corp application deployment ===" -ForegroundColor Green
Write-Host ""

# Create directory structure for Flux
$directories = @(
    "..\..\clusters\linode-lke\apps",
    "..\..\helm-charts\randomcorp\templates"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "Created directory: $dir" -ForegroundColor Cyan
    }
}

Write-Host "Creating Helm chart for Random Corp..." -ForegroundColor Yellow

# Create Chart.yaml
$chartYaml = @"
apiVersion: v2
name: randomcorp
description: Random Corp FastAPI application with SQL Server
type: application
version: 0.1.0
appVersion: "2.1.0"

dependencies:
  - name: mssql-linux
    version: 0.11.0
    repository: https://simcubeltd.github.io/simcube-helm-charts/
    condition: sqlserver.enabled
"@

$chartYaml | Out-File -FilePath "..\..\helm-charts\randomcorp\Chart.yaml" -Encoding UTF8
Write-Host "Created Chart.yaml" -ForegroundColor Green

# Create values.yaml
$valuesYaml = @"
# Random Corp Application Configuration

replicaCount: 2

image:
  repository: $Registry/randomcorp  # Update with your container registry
  tag: "latest"
  pullPolicy: IfNotPresent

service:
  type: LoadBalancer  # Will create Linode NodeBalancer
  port: 80
  targetPort: 8000

frontend:
  image:
    repository: $Registry/randomcorp-frontend
    tag: "latest"
  service:
    type: LoadBalancer
    port: 80
    targetPort: 80

# SQL Server configuration
sqlserver:
  enabled: true
  acceptEula: true
  edition: Developer  # Free for dev/test
  saPassword: "RandomCorp123!"  # Change this!
  persistence:
    enabled: true
    size: 20Gi
    storageClass: linode-block-storage-retain

# Environment variables for API
env:
  - name: SQL_SERVER_HOST
    value: "randomcorp-mssql-linux"
  - name: SQL_SERVER_PORT
    value: "1433"
  - name: SQL_SERVER_DATABASE
    value: "RandomCorpDB"
  - name: SQL_SERVER_USERNAME
    value: "sa"
  - name: SQL_SERVER_PASSWORD
    value: "RandomCorp123!"
  - name: DEBUG
    value: "false"
  - name: LOG_LEVEL
    value: "INFO"

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80

ingress:
  enabled: false  # Using LoadBalancer instead
"@

$valuesYaml | Out-File -FilePath "..\..\helm-charts\randomcorp\values.yaml" -Encoding UTF8
Write-Host "Created values.yaml" -ForegroundColor Green

# Create API deployment template
$apiDeployment = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "randomcorp.fullname" . }}-api
  labels:
    {{- include "randomcorp.labels" . | nindent 4 }}
    app.kubernetes.io/component: api
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "randomcorp.selectorLabels" . | nindent 6 }}
      app.kubernetes.io/component: api
  template:
    metadata:
      labels:
        {{- include "randomcorp.selectorLabels" . | nindent 8 }}
        app.kubernetes.io/component: api
    spec:
      containers:
        - name: api
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: 8000
              protocol: TCP
          env:
            {{- toYaml .Values.env | nindent 12 }}
          livenessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 5
            periodSeconds: 5
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ include "randomcorp.fullname" . }}-api
  labels:
    {{- include "randomcorp.labels" . | nindent 4 }}
    app.kubernetes.io/component: api
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: {{ .Values.service.targetPort }}
      protocol: TCP
      name: http
  selector:
    {{- include "randomcorp.selectorLabels" . | nindent 4 }}
    app.kubernetes.io/component: api
"@

$apiDeployment | Out-File -FilePath "..\..\helm-charts\randomcorp\templates\api-deployment.yaml" -Encoding UTF8
Write-Host "Created api-deployment.yaml" -ForegroundColor Green

# Create frontend deployment template
$frontendDeployment = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "randomcorp.fullname" . }}-frontend
  labels:
    {{- include "randomcorp.labels" . | nindent 4 }}
    app.kubernetes.io/component: frontend
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "randomcorp.selectorLabels" . | nindent 6 }}
      app.kubernetes.io/component: frontend
  template:
    metadata:
      labels:
        {{- include "randomcorp.selectorLabels" . | nindent 8 }}
        app.kubernetes.io/component: frontend
    spec:
      containers:
        - name: frontend
          image: "{{ .Values.frontend.image.repository }}:{{ .Values.frontend.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}          ports:
            - name: http
              containerPort: 80
              protocol: TCP
          livenessProbe:
            httpGet:
              path: /
              port: http
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /
              port: http
            initialDelaySeconds: 5
            periodSeconds: 5
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ include "randomcorp.fullname" . }}-frontend
  labels:
    {{- include "randomcorp.labels" . | nindent 4 }}
    app.kubernetes.io/component: frontend
spec:
  type: {{ .Values.frontend.service.type }}
  ports:
    - port: {{ .Values.frontend.service.port }}
      targetPort: {{ .Values.frontend.service.targetPort }}
      protocol: TCP
      name: http
  selector:
    {{- include "randomcorp.selectorLabels" . | nindent 4 }}
    app.kubernetes.io/component: frontend
"@

$frontendDeployment | Out-File -FilePath "..\..\helm-charts\randomcorp\templates\frontend-deployment.yaml" -Encoding UTF8
Write-Host "Created frontend-deployment.yaml" -ForegroundColor Green

# Create helpers template
$helpersTemplate = @"
{{/*
Expand the name of the chart.
*/}}
{{- define "randomcorp.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "randomcorp.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- `$name := default .Chart.Name .Values.nameOverride }}
{{- if contains `$name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name `$name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "randomcorp.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "randomcorp.labels" -}}
helm.sh/chart: {{ include "randomcorp.chart" . }}
{{ include "randomcorp.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "randomcorp.selectorLabels" -}}
app.kubernetes.io/name: {{ include "randomcorp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
"@

$helpersTemplate | Out-File -FilePath "..\..\helm-charts\randomcorp\templates\_helpers.tpl" -Encoding UTF8
Write-Host "Created _helpers.tpl" -ForegroundColor Green

# Create HPA template
$hpaTemplate = @"
{{- if .Values.autoscaling.enabled }}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ include "randomcorp.fullname" . }}-api
  labels:
    {{- include "randomcorp.labels" . | nindent 4 }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ include "randomcorp.fullname" . }}-api
  minReplicas: {{ .Values.autoscaling.minReplicas }}
  maxReplicas: {{ .Values.autoscaling.maxReplicas }}
  metrics:
    {{- if .Values.autoscaling.targetCPUUtilizationPercentage }}
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: {{ .Values.autoscaling.targetCPUUtilizationPercentage }}
    {{- end }}
{{- end }}
"@

$hpaTemplate | Out-File -FilePath "..\..\helm-charts\randomcorp\templates\hpa.yaml" -Encoding UTF8
Write-Host "Created hpa.yaml" -ForegroundColor Green

# Create Flux HelmRelease
$helmRelease = @"
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: randomcorp
  namespace: default
spec:
  interval: 5m
  chart:
    spec:
      chart: ./helm-charts/randomcorp
      sourceRef:
        kind: GitRepository
        name: randomcorp-source
        namespace: flux-system
      interval: 1m
  values:
    image:
      repository: $Registry/randomcorp
      tag: "latest"
    frontend:
      image:
        repository: $Registry/randomcorp-frontend
        tag: "latest"
"@

$helmRelease | Out-File -FilePath "..\..\clusters\linode-lke\apps\randomcorp-helmrelease.yaml" -Encoding UTF8
Write-Host "Created randomcorp-helmrelease.yaml" -ForegroundColor Green

# Create Flux GitRepository source
$gitSource = @"
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: GitRepository
metadata:
  name: randomcorp-source
  namespace: flux-system
spec:
  interval: 1m
  ref:
    branch: master
  url: https://github.com/$GitHubUser/$GitHubRepo
"@

$gitSource | Out-File -FilePath "..\..\clusters\linode-lke\apps\randomcorp-source.yaml" -Encoding UTF8
Write-Host "Created randomcorp-source.yaml" -ForegroundColor Green

Write-Host ""
Write-Host "=== Application deployment structure created! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Created files:" -ForegroundColor Cyan
Write-Host "  - helm-charts/randomcorp/ (Helm chart)" -ForegroundColor White
Write-Host "  - clusters/linode-lke/apps/ (Flux manifests)" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Update container registry URLs in values.yaml" -ForegroundColor White
Write-Host "2. Build and push your container images with .\build-and-push.ps1" -ForegroundColor White
Write-Host "3. Update GitHub repository URL in randomcorp-source.yaml" -ForegroundColor White
Write-Host "4. Commit and push these files to trigger Flux deployment" -ForegroundColor White
Write-Host ""
Write-Host "Container build commands:" -ForegroundColor Cyan
Write-Host "  docker build -t $Registry/randomcorp:latest ./api" -ForegroundColor Gray
Write-Host "  docker build -t $Registry/randomcorp-frontend:latest ." -ForegroundColor Gray
Write-Host "  docker push $Registry/randomcorp:latest" -ForegroundColor Gray
Write-Host "  docker push $Registry/randomcorp-frontend:latest" -ForegroundColor Gray

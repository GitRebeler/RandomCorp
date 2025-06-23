#!/bin/bash

# Deploy Random Corp application to LKE using Helm and Flux
# This creates the necessary Kubernetes manifests and Helm charts

set -e

echo "🚀 Setting up Random Corp application deployment"
echo ""

# Create directory structure for Flux
mkdir -p clusters/linode-lke/apps
mkdir -p helm-charts/randomcorp

echo "📁 Creating Helm chart for Random Corp..."

# Create Helm chart structure
cat > helm-charts/randomcorp/Chart.yaml << 'EOF'
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
EOF

# Create values.yaml
cat > helm-charts/randomcorp/values.yaml << 'EOF'
# Random Corp Application Configuration

replicaCount: 2

image:
  repository: your-registry/randomcorp  # Update with your container registry
  tag: "latest"
  pullPolicy: IfNotPresent

service:
  type: LoadBalancer  # Will create Linode NodeBalancer
  port: 80
  targetPort: 8000

frontend:
  image:
    repository: your-registry/randomcorp-frontend
    tag: "latest"
  service:
    type: LoadBalancer
    port: 80
    targetPort: 3000

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
EOF

# Create API deployment template
cat > helm-charts/randomcorp/templates/api-deployment.yaml << 'EOF'
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
EOF

# Create frontend deployment template
cat > helm-charts/randomcorp/templates/frontend-deployment.yaml << 'EOF'
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
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: 3000
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
EOF

# Create helpers template
cat > helm-charts/randomcorp/templates/_helpers.tpl << 'EOF'
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
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
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
EOF

# Create HPA template
cat > helm-charts/randomcorp/templates/hpa.yaml << 'EOF'
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
EOF

# Create Flux HelmRelease
cat > clusters/linode-lke/apps/randomcorp-helmrelease.yaml << 'EOF'
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
      repository: your-registry/randomcorp
      tag: "latest"
    frontend:
      image:
        repository: your-registry/randomcorp-frontend
        tag: "latest"
EOF

# Create Flux GitRepository source
cat > clusters/linode-lke/apps/randomcorp-source.yaml << 'EOF'
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: GitRepository
metadata:
  name: randomcorp-source
  namespace: flux-system
spec:
  interval: 1m
  ref:
    branch: main
  url: https://github.com/your-github-username/RandomCorp  # Update this!
EOF

echo ""
echo "✅ Application deployment structure created!"
echo ""
echo "📁 Created files:"
echo "  - helm-charts/randomcorp/ (Helm chart)"
echo "  - clusters/linode-lke/apps/ (Flux manifests)"
echo ""
echo "🔧 Next steps:"
echo "1. Update container registry URLs in values.yaml"
echo "2. Build and push your container images"
echo "3. Update GitHub repository URL in randomcorp-source.yaml"
echo "4. Commit and push these files to trigger Flux deployment"
echo ""
echo "📋 Container build commands:"
echo "  docker build -t your-registry/randomcorp:latest ./api"
echo "  docker build -t your-registry/randomcorp-frontend:latest ."
echo "  docker push your-registry/randomcorp:latest"
echo "  docker push your-registry/randomcorp-frontend:latest"

{{/*
Expand the name of the chart.
*/}}
{{- define "boutiqe-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "boutiqe-app.fullname" -}}
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
{{- define "boutiqe-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "boutiqe-app.labels" -}}
helm.sh/chart: {{ include "boutiqe-app.chart" . }}
{{ include "boutiqe-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "boutiqe-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "boutiqe-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}


{{- define "app.labels" -}}
app: {{ include "boutiqe-app.name" . }}
release: {{ .Release.Name }}
version: {{ .Chart.AppVersion }}
{{- end }}


{{/*
Create the name of the service account to use
*/}}
{{- define "boutiqe-app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "boutiqe-app.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

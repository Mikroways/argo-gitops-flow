{{- define "argo-project.argoProjectName" -}}
{{- printf "%s-%s" .Values.namespace .Values.cluster.name | trunc 63 | trimSuffix "-"  }}
{{- end }}

{{- define "argo-project.argoBaseAppName" -}}
{{- printf "%s-base" (include "argo-project.argoProjectName" . ) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "argo-project.argoAppReqName" -}}
{{- printf "%s-reqs" (include "argo-project.argoProjectName" . ) | trunc 63 | trimSuffix "-" }}
{{- end }}


{{- define "argo-project.argoClusterName" -}}
{{- printf "%s-%s" (.Values.cluster.name ) (.Values.cluster.nameSuffix) | trimSuffix "-" -}}
{{- end }}

{{- define "argo-project.argoAppName" -}}
{{- printf "%s-app" (include "argo-project.argoProjectName" . ) | trunc 63 | trimSuffix "-" }}
{{- end }}

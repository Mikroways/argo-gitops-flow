# Chart de proyecto de ArgoCD

## Descripción

Este chart se encarga de crear el proyecto y las aplicaciones de ArgoCD en el
cluster de Kubernetes. Básicamente se encarga de crear:

- El **proyecto**: Un manifiesto de tipo `AppProject` que define proyecto en
  ArgoCD, con toda la configuración de permisos para el mismo.
- Una **Aplicación base**: La aplicación de ArgoCD que se encarga de crear el
  `namespace` y demás configuraciones por defecto del mismo. Ver
  [chart de aplicación base](../argo-base-app).
- Una **Aplicación de dependencias**: Se ser necesario se puede crear alguna
  aplicación que necesite estar instalada **antes** de que se instale la
  _aplicación final_. Por ejemplo, desplegar una base de datos.
- Una **Aplicación final**: La aplicación funcional que se quiere desplegar en
  el cluster y para lo que se realizó toda la configuración previa.

## Valores

Los valores más importantes a tener en cuenta:

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `namespace` | string | `default-dev` | Namespace que utilizará el proyecto |
| `cluster.name` | string | `in-cluster` | Nombre del cluster que utilizará el proyecto si no tiene nombre se puede utilizar la dirección con `cluster.address` |
| `argo.namespace` | string | `argocd` | Namespace donde se encuentra instalado ArgoCD (en el cluster de management). En general no se debería pisar |
| `argo.readOnlyGroups` | string | `[]` | Lista de grupos de AD que tendrán acceso de solo lectura en el proyecto de ArgoCD. Solo pueden ver los objetos y leer logs |
| `argo.adminGroups` | string | `[]` | Lista de grupos de AD que tendrán acceso de administradores. Son los encargados del despliegue, entre otras cosas puede sincronizar, eliminar aplicaciones y también ejecutar la consola de los contenedores |
| `argo.repositories:` | {} | `[]` | Lista de repositorios scoped |
| `argo.baseApplication.repoURL` | string | `null` | URL del repositorio donde está el chart de dicha aplicación |
| `argo.baseApplication.path` | string | `null` | directorio donde se encuentra el chart en caso de ser un repo git |
| `argo.baseApplication.chart` | string | `null` | nombre del chart en caso de usar una registry de charts
| `argo.baseApplication.targetRevision` | string | `null` | versión del chart a instalar |
| `argo.baseApplication.helm` | string | `{}` | Valores en yaml que queremos pasarle a la aplicación de base |
| `argo.applicationRequirements.enabled` | string | `false` | Habilita la creación de la aplicación de requerimientos |
| `argo.applicationRequirements.repoURL` | string | `null` | URL del repositorio donde está el chart de dicha aplicación |
| `argo.applicationRequirements.path` | string | `null` | directorio donde se encuentra el chart en caso de ser un repo git |
| `argo.applicationRequirements.chart` | string | `null` | nombre del chart en caso de usar una registry de charts
| `argo.applicationRequirements.targetRevision` | string | `null` | versión del chart a instalar |
| `argo.applicationRequirements.helm` | string | `{}` | Valores en yaml que queremos pasarle a la aplicación de requerimientos |
| `argo.application.enabled` | string | `false` | Crear la aplicación final |
| `argo.application.repoURL` | string | `null` | Url del repositorio donde está el chart de dicha aplicación |
| `argo.application.path` | string | `null` | directorio donde se encuentra el chart en caso de ser un repo git |
| `argo.application.chart` | string | `null` | nombre del chart en caso de usar una registry de charts
| `argo.application.targetRevision` | string | `null` | versión del chart a instalar |
| `argo.application.helm` | string | `{}` | Valores en yaml que queremos pasarle a la aplicación final |

Se exhibe un ejemplo de una configuración típica para  utilizar el chart en el
archivo [`values-example.yaml`](values-example.yaml).

Para recalcar, en la configuración de `argo.application.helm` se pueden utilizar
valores en yaml directamente utilizando la clave `values: |` o bien se pueden
indicar los nombres de los archivos que contienen loso valores respecto al
repositorio indicado en `argo.application.repoURL`. Por ejemplo;

```yaml
argo:
  ...
  application:
    enabled: true
    repoURL: ssh://my-repo.git
    path: .
    targetRevision: HEAD
    helm:
      values: |
        myValue: 1
      valueFiles:
        - values.yaml
        - values-version.yaml
        - secrets+age-import:///helm-secrets-private-keys/age-key.txt?values-secrets.yaml
```

Entonces los valores indicados en `values:` tomarán precedencia respecto a los
indicados en los archivos `values.yaml`, `values-version.yaml` y
`values-secrets.yaml`. Es decir, si en algunos de esos archivos se escribe
`myValue: 2`, finalmente el valor de `myValue` será `1` de todas formas.

Esto permite que el administrador impida que los desarrolladores cambien valores
que nos interesa preservar.

> Notar que si el archivo de valores se encuentra encriptado con Age, se debe
> anteponer el prefijo
> `secrets+age-import:///helm-secrets-private-keys/age-key.txt?` al path del
> mismo, como es el caso con `values-secrets.yaml` en el ejemplo anterior.

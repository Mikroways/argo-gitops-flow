# Chart de proyecto de ArgoCD

## Descripción

Este chart se encarga de crear el proyecto y las aplicaciones de ArgoCD en el
cluster de Kubernetes. Básicamente se encarga de crear:

- El **proyecto**: Un manifiesto de tipo `AppProject` que define proyecto en
  ArgoCD, con toda la configuración de permisos para el mismo.
- Una **Aplicación base**: La aplicación de ArgoCD que se encarga de crear el
  `namespace` y demás configuraciones por defecto del mismo. Ver
  [chart de aplicación base](../argo-base-app).
- Una **Aplicación de requerimientos**: Se ser necesario se puede crear alguna
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
| `argo.readOnlyGroups` | string | `[]` | Lista de grupos que tendrán acceso de solo lectura en el proyecto de ArgoCD. Solo pueden ver los objetos y leer logs |
| `argo.adminGroups` | string | `[]` | Lista de grupos que tendrán acceso de administradores. Son los encargados del despliegue, entre otras cosas puede sincronizar, eliminar aplicaciones y también ejecutar la consola de los contenedores |
| `argo.repositories:` | {} | `[]` | Lista de repositorios scoped. Ver la sección que explica más sobre estos repositorios |
| `argo.extraDestinations:` | [] | `[]` | Lista de namespaces de destino extra que se permitirán en el proyecto |
| `argo.clusterResourceWhitelist:` | [] | `[]` | Lista de recursos no namespacebles permitidos |
| `argo.clusterResourceBlacklist:` | [] | `[]` | Lista de recursos no namespacebles no permitidos |
| `argo.namespaceResourceWhitelist:` | [] | `[]` | Lista de recursos namespacebles permitidos |
| `argo.namespaceResourceBlacklist:` | [] | `[]` | Lista de recursos namespacebles no permitidos |
| `argo.baseApplication.repoURL` | string | `null` | URL del repositorio donde está el chart de dicha aplicación |
| `argo.baseApplication.path` | string | `null` | directorio donde se encuentra el chart en caso de ser un repo git |
| `argo.baseApplication.chart` | string | `null` | nombre del chart en caso de usar una registry de charts
| `argo.baseApplication.targetRevision` | string | `null` | versión del chart a instalar |
| `argo.baseApplication.helm.values` | string | "" | Valores en yaml que queremos pasarle a la aplicación de base. Son valores con precedencia, como los usados con `helm --set`. Al ser un string, el formato será como un json, pero se usa el pipe `\|` para representar un texto con enters en YAML |
| `argo.applicationRequirements.enabled` | string | `false` | Habilita la creación de la aplicación de requerimientos |
| `argo.applicationRequirements.source` | {} | null | Opciones disponibles en source de una aplicacion ArgoCD. A decir `repoURL`, `targetRevision`, `path`, `helm` (values y valueFiles) |
| `argo.applicationRequirements.sources` | [] | [] | Mútiples source. La idea de este atributo, es el de poder tener un source con la app, y otro con los values usando la interpolación. Ver más en las sección de mútltiples sources. |
| ~~`argo.applicationRequirements.repoURL`~~ | string | `null` | URL del repositorio donde está el chart de dicha aplicación |
| ~~`argo.applicationRequirements.path`~~ | string | `null` | directorio donde se encuentra el chart en caso de ser un repo git |
| ~~`argo.applicationRequirements.chart`~~ | string | `null` | nombre del chart en caso de usar una registry de charts
| ~~`argo.applicationRequirements.targetRevision`~~ | string | `null` | versión del chart a instalar |
| ~~`argo.applicationRequirements.helm.values`~~ | string | "" | Valores en yaml que queremos pasarle a la aplicación de requerimientos. Son valores con precedencia, como los usados con `helm --set`. Al ser un string, el formato será como un json, pero se usa el pipe `\|` para representar un texto con enters en YAML |
| ~~`argo.applicationRequirements.helm.valueFiles`~~ | [] | [] | Lista de archivos de values en yaml que queremos pasarle a la aplicación de requerimientos. Estos directorios deben estar en el mismo repoURL y son relativos al path, no admitiendo salirse del mismo por cuestiones de seguridad|
| `argo.applicationRequirements.syncPolicy` | `{}` | `{}` | [Argocd Sync Policy](https://argo-cd.readthedocs.io/en/stable/user-guide/auto_sync/) para esta aplicación |
| `argo.application.enabled` | string | `false` | Crear la aplicación final |
| `argo.application.source` | {} | null | Opciones disponibles en source de una aplicacion ArgoCD. A decir `repoURL`, `targetRevision`, `path`, `helm` (values y valueFiles) |
| `argo.application.sources` | [] | [] | Mútiples source. La idea de este atributo, es el de poder tener un source con la app, y otro con los values usando la interpolación. Ver más en las sección de mútltiples sources. |
| ~~`argo.application.repoURL`~~ | string | `null` | Url del repositorio donde está el chart de dicha aplicación |
| ~~`argo.application.path`~~ | string | `null` | directorio donde se encuentra el chart en caso de ser un repo git |
| ~~`argo.application.chart`~~ | string | `null` | nombre del chart en caso de usar una registry de charts
| ~~`argo.application.targetRevision`~~ | string | `null` | versión del chart a instalar |
| ~~`argo.application.helm.values`~~ | string | "" | Valores en yaml que queremos pasarle a la aplicación de requerimientos. Son valores con precedencia, como los usados con `helm --set`. Al ser un string, el formato será como un json, pero se usa el pipe `\|` para representar un texto con enters en YAML |
| ~~`argo.application.helm.valueFiles`~~ | [] | [] | Lista de archivos de values en yaml que queremos pasarle a la aplicación de requerimientos. Estos directorios deben estar en el mismo repoURL y son relativos al path, no admitiendo salirse del mismo por cuestiones de seguridad|
| `argo.application.syncPolicy` | `{}` | `{}` | [Argocd Sync Policy](https://argo-cd.readthedocs.io/en/stable/user-guide/auto_sync/) para esta aplicación |

## Ejemplo
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
    source:
      repoURL: ssh://my-repo.git
      path: .
      targetRevision: main
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

Si se desean utilizar helm charts con los values únicamente en un repositorio,
podemos usar este otro ejemplo:

```yaml
argo:
  ...
  application:
    enabled: true
    sources:
      - repoURL: 'https://prometheus-community.github.io/helm-charts'
        chart: prometheus
        targetRevision: 15.7.1
        helm:
          valueFiles:
          - $values/prometheus/values.yaml
          - secrets+age-import:///helm-secrets-private-keys/age-key.txt?$values/prometheus/secrets.yaml
      - repoURL: 'https://git.example.com/org/value-files.git'
        targetRevision: dev
        ref: values
```

Acá ahora puede verse que tenemos dos repositorios, uno de helm charts, donde se
especifica el chart y version a usar, pero los valores usan `$values` haciendo
referencia al segundo repositorio, que es desde donde se tomarán los valores: un
repositorio git en la rama dev.

### Cambio que será eliminado en siguientes versiones

Se provee un ejemplo que mantiene la anterior sintaxis que no permitía escribir
el `argo.source` ni `argo.sources`. Se provee un ejemplo en este repositorio
llamado [`values-example-deprecated.yaml`](values-example-deprecated.yaml) con
este formato que sugerimos eliminar para versiones superiores a 1.5. La versión
1.5 es la que provee soporte a ambos formatos.

## Sobre los repositorios

Argo CD permite dar de alta repositorios, que son secretos de kubernetes y se
configuran luego para poder hacer un git clone. Ahora bien, cuando los
repositorios son registries OCI, como es el caso de los helm charts, debe
tenerse especial cuidado respecto de cómo se configuran los repositorios OCI:

* Un repositorio OCI es una URL como por ejemplo: ghcr.io, registry.gitlab.com,
  registry-1.docker.io, etc.
* Si se utiliza un path por detrás de un repositorio OCI, esto no hará
  diferencia.
    * Sin embargo, en Gitlab, el acceso a
      registry.gitlab.io/mikroways/repo1/app1 es diferente de
      registry.gitlab.io/other/repo2/app2.
    * Pero al configurar la registry para el primer o segundo caso, servirá
      sólo uno de ambos.

> Este es el mismo funcionamiento que tiene docker login. Uno no puede usar un
> mismo usuario para descargar imágenes de dos repositorios diferentes en gitlab
> si el usuario no tiene permiso para ambos.

> Todo el ejemplo aplica igual a GitHub.

## Importante para los upgrades

* El release 1.3 no conviene actualizarlo a 1.4 porque debe modificarse la
  estructura de los valores que se usaban. El problema es la incorporación de
  source y sources.
* La version 1.5 es compatible con 1.3 y 1.4, es una version que es compatible
  hacia atrás y permite la transición sin mayores problems de 1.3 a la nueva
  forma de trabajo con source y sources. La idea es usar esta version para
  transicionar a 1.6.

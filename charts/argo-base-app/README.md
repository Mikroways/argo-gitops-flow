# Chart para Aplicación base de argo

## Descripción

Este chart se encarga de crear la aplicación base (o _bootstrap_) de ArgoCD en
el cluster de Kubernetes. Básicamente se encarga de crear:

- **Un `Namespace`:** Donde vivirán todos los recursos del proyecto en el cluster.
- **Un `Secret` del tipo `docker-registry`:** Para poder hacer pull de las imágenes
  de los contenedores de las aplicaciones que se quieren instalar. _Opcional._
- **Una [`ResourceQuota`](https://kubernetes.io/docs/concepts/policy/resource-quotas/):**
  Limita el consumo de recursos de este namespace. Se pueden limitar la cantidad
  de objetos del namespace por tipo, ejemplo `pods`, `pvc`, `services`, y
  también el total de requerimientos y limites de cpu y memoria.
- **Un [`LimitRange`](https://kubernetes.io/docs/concepts/policy/limit-range/):**
  Es una política para restringir las asignaciones de recursos (a Pods o
  Contenedores) en el namespace. Se pueden establecer límites y requerimientos
  por defecto para los recursos de CPU y memoria.
- **Una serie de `NetworkPolicies`:** que nos permitirán restringir el tráfico
  desde o hacia el namespace en cuestión. El propio archivo de values deja
  ejemplos de algunos casos. _Opcional._
- **Una serie de manifiestos de k8s:** que servirán para definir cualquier otro
  objeto que se quiera crear en el cluster. _Opcional._

## Valores

| Clave | Tipo | Default | Descripción |
|-------|------|---------|-------------|
| `namespace` | string | `default-dev` | Namespace que utilizará el proyecto |
| `namespaceLabels` | obj | {} | Labels para el namespace creado |
| `registrySecret.name` | string | `container-registry` | **Deprecado**. Nombre del secreto usado por el [Registry secret](#registry-secret) |
| `registrySecret.dockerconfigjson` | string | `null` | **Deprecado**. String encodeado que contiene los datos para conectarse a la registry, para instrucciones de cómo generarlo ver [Registry secret](#registry-secret) |
| `registrySecrets` | list | `[]` | Lista de objetos con los campos `.name` y `.dockerconfigjson` para crear varios secretos que contienen los datos para conectarse a la registry, para instrucciones de cómo generarlo ver [Registry secret](#registry-secret). **Nueva funcionalidad que reemplaza `registrySecret`**. |
| `quota.enabled` | boolean | `true` | Definir el ResourceQuota. Por defecto sí |
| `quota.requests.cpu` | string | `'1'` | La suma de los requerimientos de CPU de los pods del namespace, que estén no terminados, no puede superar este valor.  |
| `quota.requests.memory` | string | `1Gi` | Idem ant. pero con los requerimientos de memoria  |
| `quota.limits.cpu` | string | `'2'` | Idem ant. pero con la suma de límites de CPU |
| `quota.limits.memory` | string | `2Gi` | Idem ant. pero con los límites de memoria |
| `quota.pods` | string | `"10"` |  |
| `quota.persistentvolumeclaims` | string | `"20"` | El número total de `PersistentVolumeClaims` que pueden existir en el namespace. |
| `quota.resourcequotas` | string | `"1"` | El número total de `pods` en un estado no terminal que puede existir en el namespace |
| `quota.services` | string | `"5"` | El número total de `Services` que pueden existir en el espacio de nombres |
| `limits.enabled` | boolean | `true` | Definir el LimitRange. Por defecto sí |
| `limits.default.cpu` | string | `200m` | El límite de CPU por defecto para los pods/contendores del namespace |
| `limits.default.memory` | string | `512Mi` | El límite de memoria por defecto para los pods/contendores del namespace |
| `limits.defaultRequest.cpu` | string | `100m` | Requerimientos de CPU por defecto para los pods/contendores del namespace |
| `limits.defaultRequest.memory` | string | `256Mi` | Requerimientos de memoria por defecto para los pods/contendores del namespace |
| `limits.type` | string | `Container` | Define si los limites aplican por contenedor o pod |
| `networkPolicies` | list | `[]` | Define una lista de name,spec que permiten definir NetworkPolicy objects. El spec puede usar variables del propio .Values. Ver el [values.yaml](./values.yaml) provisto |
| `extraManifests` | list | `[]` | Define una lista de manifiestos a instalar en el cluster. Soporta el templetizado de Helm. Se brinda una explicación en [Extra Manifests](#extra-manifests) |

## Registry secret

Ya que difieren las formas de conectarse a las distintas registries, se deja a
criterio del usuario la forma de generar el `dockerconfigjson`.

Una forma es utilizando `kubectl` con la opción `--dry-run` (para que no cree
nada). Ejemplo:

Tenemos una registry en `https://registry.gitlab.com` cuyas credenciales son:

- usuario: `USUARIO`
- contraseña: `TOKEN123`

```bash
DOCKERCONFIGJSON=$(kubectl create secret docker-registry regcred \
  --docker-server=registry.gitlab.com \
  --docker-username=USUARIO \
  --docker-password=TOKEN123 \
  --dry-run=client -o jsonpath='{ .data.\.dockerconfigjson }') \
  && echo $DOCKERCONFIGJSON

eyJhdXRocyI6eyJyZWdpc3RyeS5naXRsYWIuY29tIjp7InVzZXJuYW1lIjoiVVNVQVJJTyIsInBhc3N3b3JkIjoiVE9LRU4xMjMiLCJhdXRoIjoiVlZOVlFWSkpUenBVVDB0RlRqRXlNdz09In19fQ==
```

Esto nos devuelve (y guarda en una variable de ambiente) el string que debemos
utilizar en cada valor `registrySecrets[x].dockerconfigjson` del chart.

> Antes el chart soportaba únicamente un único registrySecret. Ahora soporta una
> lista de registrySecrets.

Podemos ver que simplemente es un base 64 de un json de los datos provistos:
  
```bash
❯ echo $DOCKERCONFIGJSON | base64 -d | jq
{
  "auths": {
    "registry.gitlab.com": {
      "username": "USUARIO",
      "password": "TOKEN123",
      "auth": "VVNVQVJJTzpUT0tFTjEyMw=="
    }
  }
}
```

En el campo `auth` se repite el usuario y contraseña, nuevamente encodeado en
base 64.

```bash
❯ echo "VVNVQVJJTzpUT0tFTjEyMw==" | base64 -d
USUARIO:TOKEN123
```

## Extra Manifests

Para crear cualquier objeto se puede utilizar el campo `extraManifests` del
chart. Para crear un objeto de manera literal simplemente se debe copiar el
manifiesto como un item de la lista. Por ejemplo:

```yaml
extraManifests:
  - apiVersion: v1
    kind: ConfigMap
    metadata:
      name: my-configmap
      namespace: my-namespace
    data:
      my-key: my-value
```

También se soporta el templetizado de Helm, para ello el manifiesto debe ser un `string`:

```yaml
extraManifests:
  - |
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: my-configmap
      namespace: {{ .Values.namespace }}
    data:
      my-key: {{ .Values.myValue }}
```

> **Nota:** Para que funcione, el [proyecto de argo](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#projects)
> en el cual se despliega esta aplicación deber tener permisos para crear
> objetos del **`kind`** solicitado en ese **`namespace`**. Por defecto, se
> despliega en el proyecto [`default`](https://gitlab.com/mikroways/k8s/charts/gitops/argo-project/-/blob/main/values.yaml?ref_type=heads#L17)
> que puede, también predeterminadamente, crear cualquier recurso en cualquier destino.

### Ejemplo: `extraManifests` para hacer Backups

Teniendo instalado [Velero](https://velero.io/docs/v1.11/basic-install/) en el
cluster, se pueden agregar manifiestos para crear backups programados:

```yaml
extraManifests:
  - |
    apiVersion: velero.io/v1
    kind: Schedule
    metadata:
      name: {{ $.Values.namespace }}-daily
      namespace: velero
    spec:
      schedule: 0 3 * * 1-6
      template:
        includedNamespaces:
          - {{ $.Values.namespace }}
        ttl: 168h0m0s
  - |
    apiVersion: velero.io/v1
    kind: Schedule
    metadata:
      name: {{ $.Values.namespace }}-weekly
      namespace: velero
    spec:
      schedule: 0 3 * * 0
      template:
        includedNamespaces:
          - {{ $.Values.namespace }}
        ttl: 720h0m0s
  - |
    apiVersion: velero.io/v1
    kind: Schedule
    metadata:
      name: {{ $.Values.namespace }}-monthly
      namespace: velero
    spec:
      schedule: 0 3 1 * *
      template:
        includedNamespaces:
          - {{ $.Values.namespace }}
        ttl: 8640h0m0s
```

Esto creará tres backups programados:

- `daily`: De Lunes a Sábado a las 03:00 a.m. con retención de 168 horas (7 * 24h), o 1 semana.
- `weekly`: Todos los domingos a las 03:00 a.m. con retención de 720 horas (30 * 24h), aprox. 1 mes.
- `monthly`: El primer día de cada mes a las 03:00 a.m. con retención de 8640 horas (360 * 24h), aprox. 1 año.

> Sobre los campos del `schedule.spec`:
>
> - `schedule`: es una expresión de tipo [Cron](https://crontab.guru/) que
>   define cuándo ejecutar el backup.
> - `ttl`: describe cuánto tiempo debe conservarse la copia de seguridad con un
>   string [time.Duration](https://pkg.go.dev/maze.io/x/duration#ParseDuration).
>   **Cuidado:** solo usar unidades de tiempo hasta la hora (`h`), ya que
>   **`d` (_day_), `w` (_week_), y `y` (_year_) no funcionan**. Ejemplos:
>   `"4h30m"` cuatro horas y media, `"720h"` un mes. Se ha reportado en Github:
>   [#6552](https://github.com/vmware-tanzu/velero/issues/6552)

Más info en [Velero Docs: Schedules](https://velero.io/docs/v1.11/api-types/schedule/)
o con `kubectl explain schedules.spec.template`.

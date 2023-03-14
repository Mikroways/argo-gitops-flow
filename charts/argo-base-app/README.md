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
- **Una serie de NetworkPolicies:** que nos permitirán restringir el tráfico
  desde o hacia el namespace en cuestión. El propio archivo de values deja
  ejemplos de algunos casos. _Opcional._

## Valores

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `namespace` | string | `default-dev` | Namespace que utilizará el proyecto |
| `namespaceLabels` | string | {} | Labels para el namespace creado |
| `registrySecret.name` | string | `container-registry` | **Deprecado**. Nombre del secreto usado por el [Registry secret](#registry-secret) |
| `registrySecret.dockerconfigjson` | string | `null` | **Deprecado**. String encodeado que contiene los datos para conectarse a la registry, para instrucciones de cómo generarlo ver [Registry secret](#registry-secret) |
| `registrySecrets` | list | `[]` | Lista de objetos con los campos `.name` y `.dockerconfigjson` para crear varios secretos que contienen los datos para conectarse a la registry, para instrucciones de cómo generarlo ver [Registry secret](#registry-secret). **Nueva funcionalidad que reemplaza `registrySecret`**. |
| `quota.requests.enabled` | boolean | `true` | Definir el ResourceQuota. Por defecto sí |
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
| `networkPolicies` | string | `[]` | Define una lista de name,spec que permiten definir NetworkPolicy objects. El spec puede usar variables del propio .Values. Ver el values.yaml provisto |

## Registry secret

Ya que difieren las formas de conectarse a las distintas registries, se deja a
criterio del usuario la forma de generar el `dockerconfigjson`.

Una forma es utilizando `kubectl` con la opción `--dry-run` (para que no cree
nada). Ejemplo:

Tenemos una registry en `https://registry.inta.gob.ar` cuyas credenciales son:

- usuario: `USUARIO`
- contraseña: `TOKEN123`

```bash
DOCKERCONFIGJSON=$(kubectl create secret docker-registry regcred \
  --docker-server=registry.inta.gob.ar \
  --docker-username=USUARIO \
  --docker-password=TOKEN123 \
  --dry-run=client -o jsonpath='{ .data.\.dockerconfigjson }') \
  && echo $DOCKERCONFIGJSON

eyJhdXRocyI6eyJyZWdpc3RyeS5pbnRhLmdvYi5hciI6eyJ1c2VybmFtZSI6IlVTVUFSSU8iLCJwYXNzd29yZCI6IlRPS0VOMTIzIiwiYXV0aCI6IlZWTlZRVkpKVHpwVVQwdEZUakV5TXc9PSJ9fX0=
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
    "registry.inta.gob.ar": {
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

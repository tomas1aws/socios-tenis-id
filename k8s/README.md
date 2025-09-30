# Despliegue completo en Kubernetes

Este directorio contiene los manifiestos necesarios para levantar la API de "Socios Tenis", Prometheus y Grafana dentro del mismo namespace (`socios-tenis`). Las configuraciones están pensadas para ambientes de laboratorio/local con `minikube` o `kind`, exponiendo servicios como `NodePort` para que se puedan consumir desde `localhost`.

## Orden sugerido de despliegue

```bash
kubectl apply -f namespace.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f prometheus.yaml
kubectl apply -f grafana.yaml
```

> Si ya tenías recursos creados, podés relanzarlos con `kubectl apply -f <archivo>` sin borrar el namespace.

## Accesos rápidos

| Servicio      | URL                      | Usuario | Password |
|---------------|-------------------------|---------|----------|
| Aplicación    | http://localhost:30080  | -       | -        |
| Prometheus    | http://localhost:30090  | -       | -        |
| Grafana       | http://localhost:30300  | admin   | admin    |

> Para Minikube podés usar `minikube service <service-name> -n socios-tenis --url` si preferís evitar los `NodePort` fijados.

## Cómo validar que las métricas llegan

1. Abre Prometheus y revisa el apartado **Status → Targets**. Debe aparecer `socios-tenis` con estado `UP`.
2. En Grafana ingresa con `admin / admin` y crea un dashboard nuevo agregando un panel con la query `http_requests_total` para confirmar que se recolectan métricas desde la API.

## Limpieza

```bash
kubectl delete namespace socios-tenis
```

Esto eliminará todos los recursos desplegados en este ejemplo.

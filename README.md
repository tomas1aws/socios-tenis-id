# Socios Tenis ID - Guía de despliegue local con métricas

Este proyecto contiene una API en FastAPI que expone métricas Prometheus mediante `prometheus_fastapi_instrumentator`. A continuación se resume cómo construir la imagen, desplegarla en Minikube y habilitar el stack de observabilidad (Prometheus + Grafana) usando `kube-prometheus-stack`.

## Prerrequisitos

- Docker
- Minikube configurado con el driver Docker (`minikube start --driver=docker`)
- Kubectl
- Helm 3

## Paso a paso

1. **Construir y publicar la imagen (opcional si usas DockerHub)**
   ```bash
   ./run.sh build-push
   ```

2. **Iniciar Minikube**
   ```bash
   ./run.sh mk-up
   ```

3. **Desplegar la aplicación**
   ```bash
   ./run.sh mk-deploy
   ```
   Esto crea el namespace `socios-tenis`, despliega el `Deployment` y expone la API en el puerto `30080` del nodo de Minikube.

4. **Instalar Prometheus y Grafana**
   ```bash
   ./run.sh monitoring-up
   ```
   Este comando instala/actualiza `kube-prometheus-stack` en el namespace `monitoring`. El `ServiceMonitor` del proyecto está etiquetado con `release: kube-prometheus-stack`, por lo que el operador detectará automáticamente la API y comenzará a recolectar métricas de `/metrics`.

5. **Acceder a la API**
   ```bash
   ./run.sh urls
   ```
   Esto abre un túnel a través de `minikube service` hacia la API (`http://localhost:30080`).

6. **Acceder a Grafana y Prometheus**
   - Grafana:
     ```bash
     kubectl port-forward svc/kube-prometheus-stack-grafana -n monitoring 3000:80
     ```
     Luego abre http://localhost:3000 (usuario `admin`, contraseña obtenida con `kubectl get secret kube-prometheus-stack-grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 --decode`).

   - Prometheus:
     ```bash
     kubectl port-forward svc/kube-prometheus-stack-prometheus -n monitoring 9090:9090
     ```
     Visita http://localhost:9090 para consultar las métricas.

7. **Eliminar recursos**
   ```bash
   ./run.sh down
   ./run.sh monitoring-down
   ```

## Observabilidad

- El `Service` expone el puerto `8000` con el nombre `http`, lo que permite al `ServiceMonitor` encontrar el endpoint de métricas.
- `prometheus_fastapi_instrumentator` expone `/metrics` automáticamente, por lo que no se requiere configuración adicional.

Con estos pasos deberías poder desplegar la aplicación, habilitar el stack de monitoreo y visualizar las métricas en Grafana/Prometheus.

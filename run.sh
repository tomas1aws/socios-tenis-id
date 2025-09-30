#!/bin/bash
set -euo pipefail

print_section() {
  echo
  echo "==================== $1 ===================="
}

ensure_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "❌ No se encontró el comando '$1'. Por favor instalalo antes de continuar." >&2
    exit 1
  fi
}

case ${1:-} in
  build-push)
    echo "🚀 Construyendo y subiendo imagen a DockerHub..."
    cd backend
    docker build -t tomas1aws/socios-tenis-id:latest .
    docker push tomas1aws/socios-tenis-id:latest
    cd ..
    ;;

  mk-up)
    echo "🚀 Iniciando Minikube..."
    minikube start --driver=docker
    ;;

  mk-deploy)
    echo "📦 Aplicando manifests de Kubernetes..."
    kubectl apply -f k8s/namespace.yaml
    kubectl apply -f k8s/deployment.yaml
    kubectl apply -f k8s/service.yaml
    kubectl apply -f k8s/servicemonitor.yaml
    ;;

  monitoring-up)
    echo "📈 Instalando kube-prometheus-stack (Prometheus + Grafana)..."
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
      --namespace monitoring --create-namespace
    ;;

  monitoring-down)
    echo "🧹 Eliminando kube-prometheus-stack..."
    helm uninstall kube-prometheus-stack -n monitoring || true
    ;;

  urls)
    echo "🌍 Abriendo la API en navegador..."
    minikube service socios-tenis-service -n socios-tenis
    ;;

  down)
    echo "🛑 Apagando todo..."
    kubectl delete -f k8s/service.yaml || true
    kubectl delete -f k8s/deployment.yaml || true
    kubectl delete -f k8s/servicemonitor.yaml || true
    kubectl delete -f k8s/namespace.yaml || true
    minikube stop
    ;;

  all-in-one)
    echo "🚀 Despliegue completo (aplicación + monitoreo + port-forwards)"

    ensure_command docker
    ensure_command minikube
    ensure_command kubectl
    ensure_command helm

    IMAGE_NAME="${IMAGE_NAME:-tomas1aws/socios-tenis-id:latest}"

    print_section "Construyendo imagen Docker"
    (cd backend && docker build -t "$IMAGE_NAME" .)

    print_section "Iniciando Minikube"
    if ! minikube status >/dev/null 2>&1; then
      minikube start --driver=docker
    else
      echo "✅ Minikube ya está en ejecución"
    fi

    print_section "Sincronizando imagen con Minikube"
    minikube image load "$IMAGE_NAME"

    print_section "Aplicando manifests de Kubernetes"
    kubectl apply -f k8s/namespace.yaml
    kubectl apply -f k8s/deployment.yaml
    kubectl apply -f k8s/service.yaml
    kubectl apply -f k8s/servicemonitor.yaml

    print_section "Instalando/actualizando kube-prometheus-stack"
    if ! helm repo list | grep -q '^prometheus-community'; then
      helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    fi
    helm repo update
    helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
      --namespace monitoring --create-namespace

    print_section "Esperando a que los recursos estén listos"
    kubectl -n socios-tenis wait --for=condition=available deployment/socios-tenis-deployment --timeout=240s
    kubectl -n monitoring wait --for=condition=ready pod -l app.kubernetes.io/name=grafana --timeout=300s
    kubectl -n monitoring wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus --timeout=300s

    print_section "Recuperando credenciales de Grafana"
    GRAFANA_PASSWORD=$(kubectl get secret kube-prometheus-stack-grafana -n monitoring -o jsonpath='{.data.admin-password}' | base64 --decode)
    echo "🔐 Usuario: admin"
    echo "🔐 Contraseña: $GRAFANA_PASSWORD"

    print_section "Iniciando port-forwards"
    API_LOG=$(mktemp)
    PROM_LOG=$(mktemp)
    GRAFANA_LOG=$(mktemp)

    kubectl -n socios-tenis port-forward svc/socios-tenis-service 8000:8000 >"$API_LOG" 2>&1 &
    API_PID=$!
    kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090 >"$PROM_LOG" 2>&1 &
    PROM_PID=$!
    kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80 >"$GRAFANA_LOG" 2>&1 &
    GRAFANA_PID=$!

    cleanup() {
      echo
      echo "🛑 Deteniendo port-forwards..."
      kill "$API_PID" "$PROM_PID" "$GRAFANA_PID" 2>/dev/null || true
    }
    trap cleanup EXIT

    sleep 3
    if ! kill -0 "$API_PID" >/dev/null 2>&1; then
      echo "⚠️ El port-forward de la API falló. Revisá el log en $API_LOG" >&2
    fi
    if ! kill -0 "$PROM_PID" >/dev/null 2>&1; then
      echo "⚠️ El port-forward de Prometheus falló. Revisá el log en $PROM_LOG" >&2
    fi
    if ! kill -0 "$GRAFANA_PID" >/dev/null 2>&1; then
      echo "⚠️ El port-forward de Grafana falló. Revisá el log en $GRAFANA_LOG" >&2
    fi

    echo
    echo "✅ Todo listo. Endpoints disponibles en tu máquina local:"
    echo "  • API:         http://localhost:8000"
    echo "  • Prometheus:  http://localhost:9090"
    echo "  • Grafana:     http://localhost:3000"
    echo
    echo "Presioná Ctrl+C cuando quieras cerrar los port-forwards y salir."

    wait
    ;;

  *)
    echo "Uso: ./run.sh {build-push|mk-up|mk-deploy|monitoring-up|monitoring-down|urls|down|all-in-one}"
    ;;
esac

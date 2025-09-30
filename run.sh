#!/bin/bash
set -e

case $1 in
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

  *)
    echo "Uso: ./run.sh {build-push|mk-up|mk-deploy|monitoring-up|monitoring-down|urls|down}"
    ;;
esac

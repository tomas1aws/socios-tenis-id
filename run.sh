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
    ;;

  urls)
    echo "🌍 Abriendo la API en navegador..."
    minikube service socios-tenis-service -n socios-tenis
    ;;

  down)
    echo "🛑 Apagando todo..."
    kubectl delete -f k8s/service.yaml || true
    kubectl delete -f k8s/deployment.yaml || true
    kubectl delete -f k8s/namespace.yaml || true
    minikube stop
    ;;
    
  *)
    echo "Uso: ./run.sh {build-push|mk-up|mk-deploy|urls|down}"
    ;;
esac

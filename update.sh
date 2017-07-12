#!/bin/bash

if [ -z ${PLUGIN_NAMESPACE} ]; then
  PLUGIN_NAMESPACE="default"
fi

if [ ! -z ${PLUGIN_KUBERNETES_SERVER} ]; then
  KUBERNETES_SERVER=$PLUGIN_KUBERNETES_SERVER
fi

if [ ! -z ${KUBERNETES_TOKEN} ]; then
  kubectl config set-credentials default --token=${KUBERNETES_TOKEN}
fi

if [ ! -z ${KUBERNETES_USERNAME} ]; then
  kubectl config set-credentials default --username=${KUBERNETES_USERNAME} --password=${KUBERNETES_PASSWORD}
fi

if [ ! -z ${KUBERNETES_CLIENT_CERTIFICATE} ]; then
  echo ${KUBERNETES_CLIENT_CERTIFICATE} | base64 -d > client.crt
  echo ${KUBERNETES_CLIENT_KEY} | base64 -d > client.key
  kubectl config set-credentials default --server=${KUBERNETES_SERVER} --client-certificate=client.crt --client-key=client.key
fi
if [ ! -z ${KUBERNETES_CERT} ]; then
  echo ${KUBERNETES_CERT} | base64 -d > ca.crt
  kubectl config set-cluster default --server=${KUBERNETES_SERVER} --certificate-authority=ca.crt
else
  echo "WARNING: Using insecure connection to cluster"
  kubectl config set-cluster default --server=${KUBERNETES_SERVER} --insecure-skip-tls-verify=true
fi

kubectl config set-context default --cluster=default --user=default
kubectl config use-context default

# kubectl version
IFS=',' read -r -a DEPLOYMENTS <<< "${PLUGIN_DEPLOYMENT}"
IFS=',' read -r -a CONTAINERS <<< "${PLUGIN_CONTAINER}"
for DEPLOY in ${DEPLOYMENTS[@]}; do
  echo Deploying to $KUBERNETES_SERVER
  for CONTAINER in ${CONTAINERS[@]}; do
    kubectl -n ${PLUGIN_NAMESPACE} set image deployment/${DEPLOY} \
      ${CONTAINER}=${PLUGIN_REPO}:${PLUGIN_TAG} --record
  done
done

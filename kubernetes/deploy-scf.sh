#!/bin/bash -xe

KUBECONFIG=${KUBECONFIG:?"Please make sure that KUBECONFIG is set"}

SECRET=$(kubectl get pods --namespace uaa -o jsonpath='{.items[*].spec.containers[?(.name=="uaa")].env[?(.name=="INTERNAL_CA_CERT")].valueFrom.secretKeyRef.name}')
CA_CERT="$(kubectl get secret $SECRET --namespace uaa -o jsonpath="{.data['internal-ca-cert']}" | base64 --decode -)"

set +e
helm list | grep scf
FOUND=$?
set -e

if [[ $FOUND -eq 0 ]]; then
    echo "UPGRADE"
    helm upgrade scf ~/workspace/eirini-release/scf/hnative/cf \
        --namespace scf \
        --values ~/workspace/bits-service-private-config/kube-clusters/bits-marry-eirini/scf-config-values.yaml \
        --set "secrets.UAA_CA_CERT=${CA_CERT}"
else
    echo "INSTALL"
    helm install ~/workspace/eirini-release/scf/hnative/cf \
        --namespace scf \
        --name scf \
        --values ~/workspace/bits-service-private-config/kube-clusters/bits-marry-eirini/scf-config-values.yaml \
        --set "secrets.UAA_CA_CERT=${CA_CERT}"
fi

# TODO wait for containers
#!/bin/bash -ex

mkdir -p "deployment-vars/environments/${ENVIRONMENT_NAME}"
deployment_vars=$(readlink -f deployment-vars/environments/${ENVIRONMENT_NAME}/deployment-vars.yml)
director_uuid=$(bosh -t "${BOSH_TARGET}" status --uuid)

# TODO: (ae, pego) Get rid of '-o'??

if [[ "${BLOBSTORE_TYPE}" != 'webdav' ]] &&
   [[ "${BLOBSTORE_TYPE}" != 's3' ]] &&
   [[ "${BLOBSTORE_TYPE}" != 'local' ]]; then
  echo "Unknown blobstore type: ${BLOBSTORE_TYPE}"
  exit 1
fi

case "${IAAS}" in
'bosh-lite')
  iaas='-o cf-deployment/operations/bosh-lite.yml'
  ;;
'aws')
  iaas=
  ;;
*)
  echo "Unknown IAAS: ${IAAS}"
  exit 1
  ;;
esac

bosh2 interpolate cf-deployment/cf-deployment.yml \
  --vars-store "${deployment_vars}" \
  -o cf-deployment/operations/rename-deployment.yml \
  -v deployment_name="${DEPLOYMENT_NAME}" \
  ${iaas} \
  -v system_domain="${CF_DOMAIN}" \
  -o ci-tasks/operations/director-uuid.yml \
  -v director_uuid="${director_uuid}" \
  -o ci-tasks/operations/stemcell-version.yml \
  -v stemcell_version="latest" \
  -o cf-deployment/operations/experimental/bits-service.yml \
  -o cf-deployment/operations/experimental/bits-service-"${BLOBSTORE_TYPE}".yml \
  -o ci-tasks/operations/bits-service-release-version.yml \
  -v bits-service-release-version=$(cat bits-service-release-version/number) \
  ${OPERATIONS} \
  ${VARIABLES} \
  > manifests/manifest.yml

echo "Content of manifests/manifest.yml:"
cat manifests/manifest.yml

REPO_DIR="$(readlink -f deployment-vars)" \
FILENAME="${deployment_vars}" \
COMMIT_MESSAGE="Update ${ENVIRONMENT_NAME} deployment vars" \
./ci-tasks/scripts/commit-file-if-changed.sh

cp -r deployment-vars updated/deployment-vars

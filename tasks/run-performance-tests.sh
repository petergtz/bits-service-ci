#!/bin/bash -ex

. ci-tasks/scripts/start-collectd.sh
start_collectd


cf_admin_password=$( \
  bosh2 int deployment-vars/environments/${ENVIRONMENT_NAME}/deployment-vars-${DEPLOYMENT_NAME}.yml \
  --path /cf_admin_password
)

cat <<EOT > $PWD/bits-service-release/src/github.com/cloudfoundry-incubator/bits-service-performance-tests/integration_aws_config.json
{
  "api": "api.${CF_DOMAIN}",
  "apps_domain": "${CF_DOMAIN}",
  "admin_user": "admin",
  "admin_password": "${cf_admin_password}",
  "skip_ssl_validation": true,
  "use_http": true
}
EOT

export CONFIG=$PWD/bits-service-release/src/github.com/cloudfoundry-incubator/bits-service-performance-tests/integration_aws_config.json
export GOPATH=$PWD/bits-service-release
export PATH=$GOPATH/bin:$PATH

cp -a deployment-vars/. deployment-vars-out
export PERFORMANCE_TEST_METRICS_CSV_FILE=$(readlink -f deployment-vars-out/${PERFORMANCE_TEST_METRICS_PREFIX}-metrics.csv)
export PERFORMANCE_TEST_SHOULD_USE_V3_PUSH
echo "PERFORMANCE_TEST_SHOULD_USE_V3_PUSH: $PERFORMANCE_TEST_SHOULD_USE_V3_PUSH"
pushd bits-service-release/src/github.com/cloudfoundry-incubator/bits-service-performance-tests
  glide install
  pushd vendor/github.com/onsi/ginkgo/ginkgo
    go install
  popd
  ginkgo
popd

# Wait for collectd to send final metrics
sleep 90

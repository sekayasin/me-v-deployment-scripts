#!/bin/bash

#exit when there's an error or unbound variable
set -euo pipefail

#get environment variables from the metadata
get_var() {
  local name="$1"

  curl -s -H "Metadata-Flavor: Google" \
    "http://metadata.google.internal/computeMetadata/v1/instance/attributes/${name}"
}

export BUCKET_NAME=$(get_var "bucketName")
export DEF_STORAGE_CLASS=$(get_var "defStorageClass")
export STORAGE_CLASS=$(get_var "storageClass")
export BUCKET_OBJECT_AGE=$(get_var "bucketObjectAge")

#set default bucket storage class
gsutil defstorageclass set ${DEF_STORAGE_CLASS} gs://${BUCKET_NAME}

#substitute variables in lifecycle_rule json file
sed -i 's/${storageClass}/'"${STORAGE_CLASS}"'/' ./lifecycle_rule.json
sed -i 's/"${bucketObjectAge}"/'"${BUCKET_OBJECT_AGE}"'/' ./lifecycle_rule.json

#set lifecycle policy
gsutil lifecycle set lifecycle_rule.json gs://${BUCKET_NAME}

#check if the policy was enabled
gsutil lifecycle get gs://${BUCKET_NAME}
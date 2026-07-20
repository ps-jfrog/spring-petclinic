#!/usr/bin/env bash
export RBV1_BUNDLE_NAME="rbv1-spring-petclinic" BUILD_ID="cmd.2026-07-20-08-53"

echo "\n *** Distribution: Query RBv1 bundle distribution \n"
export RB1_DISTRIBUTE_RESP_JSON="RB1_DISTRIBUTE-${BUILD_ID}.json"

# curl --request GET --url https://psazuse.jfrog.io/distribution/api/v1/release_bundle/rbv1-spring-petclinic/cmd.2026-07-20-08-53/distribution --header 'Content-Type: application/json' --header "Authorization: Bearer ${PSAZUSE_JF_ACCESS_TOKEN}"
curl --request GET \
  --url "https://psazuse.jfrog.io/distribution/api/v1/release_bundle/${RBV1_BUNDLE_NAME}/${BUILD_ID}/distribution" \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer ${PSAZUSE_JF_ACCESS_TOKEN}" \
  > "${RB1_DISTRIBUTE_RESP_JSON}"
cat "${RB1_DISTRIBUTE_RESP_JSON}"
echo ""

items=$(jq -c -r '.[].sites[].target_artifactory.name' "${RB1_DISTRIBUTE_RESP_JSON}")
for item in ${items}; do
  echo "${item}"
  if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    echo "   - [${item}.jfrog.io](https://${item}.jfrog.io) " >> "${GITHUB_STEP_SUMMARY}"
  fi
done

echo "\n Build Name: ${BUILD_NAME:-}   Build ID: ${BUILD_ID}  Release_BUNDLE_NAME: ${RBV1_BUNDLE_NAME} \n"

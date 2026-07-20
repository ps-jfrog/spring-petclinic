#!/usr/bin/env bash
export RBV1_BUNDLE_NAME="rbv1-spring-petclinic" BUILD_ID="cmd.2026-07-20-08-53"

echo ""
echo " *** Distribution: Query RBv1 bundle distribution "
echo ""
export RB1_DISTRIBUTE_RESP_JSON="RB1_DISTRIBUTE-${BUILD_ID}.json"

# curl --request GET --url https://psazuse.jfrog.io/distribution/api/v1/release_bundle/rbv1-spring-petclinic/cmd.2026-07-20-08-53/distribution --header 'Content-Type: application/json' --header "Authorization: Bearer ${PSAZUSE_JF_ACCESS_TOKEN}"
curl --silent --show-error --request GET \
  --url "https://psazuse.jfrog.io/distribution/api/v1/release_bundle/${RBV1_BUNDLE_NAME}/${BUILD_ID}/distribution" \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer ${PSAZUSE_JF_ACCESS_TOKEN}" \
  > "${RB1_DISTRIBUTE_RESP_JSON}"
jq . "${RB1_DISTRIBUTE_RESP_JSON}"
echo ""

# Response is an array of distribution records; each has sites[].
while IFS=$'\t' read -r target_artifactory_name status; do
  [[ -z "${target_artifactory_name}" ]] && continue
  echo "   - ${target_artifactory_name}.jfrog.io  status=${status}"
  if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    echo "   - [${target_artifactory_name}.jfrog.io](https://${target_artifactory_name}.jfrog.io)/ui/release-bundles/target/${RBV1_BUNDLE_NAME}  : ${status}" >> "${GITHUB_STEP_SUMMARY}"
  fi
done < <(jq -r '.[].sites[] | [.target_artifactory.name, .status] | @tsv' "${RB1_DISTRIBUTE_RESP_JSON}")

echo ""
echo " Build Name: ${BUILD_NAME:-}   Build ID: ${BUILD_ID}  Release_BUNDLE_NAME: ${RBV1_BUNDLE_NAME} "
echo ""


# jf rt dl --build-name="spring-petclinic" --build-number="cmd.2026-07-20-08-53" --detailed-summary 

# jf rt dl --bundle="rbv1-spring-petclinic/cmd.2026-07-20-08-53" --detailed-summary=true

clear

export JF_NAME="psazuse" JF_EDGE_NAME="psazeuwedge" JFROG_CLI_LOG_LEVEL="DEBUG" PROJECT_KEY="ps-build-promote"
export JF_RT_URL="https://${JF_NAME}.jfrog.io" RT_REPO_VIRTUAL="bpr-spring-petclinic-mvn-virtual" RT_REPO_LOCAL_DEFAULT="bpr-spring-petclinic-mvn-init-local"
export RT_REPO_LOCAL_DEV="bpr-spring-petclinic-mvn-dev-local" RT_REPO_LOCAL_QA="bpr-spring-petclinic-mvn-qa-local" RT_REPO_LOCAL_PROD="bpr-spring-petclinic-mvn-prod-local"

export BUILD_NAME="spring-petclinic" BUILD_ID="cmd.$(date '+%Y-%m-%d-%H-%M')" 
export EVD_KEY_PRIVATE="$(cat ~/.ssh/jfrog_evd_private.pem)" EVD_KEY_ALIAS="KRISHNAM_JFROG_EVD_PUBLICKEY"

jf config use ${JF_NAME}

echo " ** Maven package **"
jf mvnc --global --repo-resolve-releases ${RT_REPO_VIRTUAL} --repo-resolve-snapshots ${RT_REPO_VIRTUAL} --repo-deploy-releases ${RT_REPO_VIRTUAL} --repo-deploy-snapshots ${RT_REPO_VIRTUAL}
jf mvn clean install -DskipTests=true --build-name=${BUILD_NAME} --build-number=${BUILD_ID} --project="${PROJECT_KEY}" --detailed-summary=true


sleep 2
echo "\n*** Build publish: ${BUILD_NAME}  ${BUILD_ID} \n"
jf rt bag ${BUILD_NAME} ${BUILD_ID} --project="${PROJECT_KEY}"
jf rt bce ${BUILD_NAME} ${BUILD_ID} --project="${PROJECT_KEY}"
jf rt bp ${BUILD_NAME} ${BUILD_ID} --project="${PROJECT_KEY}"

# ref: https://docs.jfrog.com/artifactory/docs/generic-files#setting-file-properties
# jf rt sp "org=ps;team=arch" --build="spring-petclinic/cmd.2026-07-13-13-48" --project="ps-build-promote"
jf rt sp "org=ps;team=arch;buildinfo;ts=ts-${BUILD_ID}" --build="${BUILD_NAME}/${BUILD_ID}" --project="${PROJECT_KEY}"

echo "\n*** Build Promote: SNAPSHOT to DEV\n"
jf rt bpr ${BUILD_NAME} ${BUILD_ID} ${RT_REPO_LOCAL_DEV} --status="Promoting build SNAPSHOT to DEV" --project="${PROJECT_KEY}"
jf rt sp "env=DEV;" --build="${BUILD_NAME}/${BUILD_ID}" --project="${PROJECT_KEY}"

echo "\n*** Build Promote: DEV to QA\n"
jf rt bpr ${BUILD_NAME} ${BUILD_ID} ${RT_REPO_LOCAL_QA} --status="Promoting build DEV to QA" --project="${PROJECT_KEY}"
jf rt sp "env=QA;" --build="${BUILD_NAME}/${BUILD_ID}" --project="${PROJECT_KEY}"


echo "\n*** Build Promote: QA to Production\n"
jf rt bpr ${BUILD_NAME} ${BUILD_ID} ${RT_REPO_LOCAL_PROD} --status="Promoting build QA to Production" --project="${PROJECT_KEY}"
jf rt sp "env=PROD;" --build="${BUILD_NAME}/${BUILD_ID}" --project="${PROJECT_KEY}"

# ref: https://jfrog.com/help/r/jfrog-distribution-documentation/generate-and-upload-signing-keys
echo "\n *** Distribution: Create RBv1, sign, and distribute to SaaS Edge \n"
export RBv1_SPEC_JSON="rbv1-spec-info.json" RBv1_BUNDLE_NAME="rbv1-${BUILD_NAME}"
# MUST use single quotes — in double quotes "$00" expands via $0 (e.g. jfrog./script.sh0)
# and Distribution returns "Wrong passphrase for GPG key".
# Override anytime with: export RBV1_GPG_PASSPHRASE='your-passphrase'
export RBV1_GPG_PASSPHRASE="${RBV1_GPG_PASSPHRASE:-jfrog\$00}"

# RBv1 File Spec requires pattern or aql. Prefer props to scope to this build — the "build"
# field is often ignored by Distribution v1 AQL generation (can pull the whole repo tree).
# ref: https://docs.jfrog.com/artifactory/docs/using-file-specs#create-and-update-release-bundle-v1-commands-spec-schema
cat > "${RBv1_SPEC_JSON}" <<EOF
{
  "files": [
    {
      "pattern": "${RT_REPO_LOCAL_PROD}/org/springframework/samples/spring-petclinic/*",
      "props": "build.name=${BUILD_NAME};build.number=${BUILD_ID}"
    }
  ]
}
EOF
cat "${RBv1_SPEC_JSON}"
printf 'Using RBV1_GPG_PASSPHRASE length=%s (value redacted)\n' "${#RBV1_GPG_PASSPHRASE}"

# Stop before distribute if create/sign fails (unsigned bundles cannot be distributed).
set -e
echo "\n *** Distribution: Create and sign RBv1 \n"
# ref: https://docs.jfrog.com/artifactory/docs/distribution-through-cli#creating-a-release-bundle
jf ds rbc "${RBv1_BUNDLE_NAME}" "${BUILD_ID}" --spec="${RBv1_SPEC_JSON}" --sign --passphrase="${RBV1_GPG_PASSPHRASE}" --detailed-summary

echo "\n *** Distribution: Distribute RBv1 to SaaS Edge \n"
# ref: https://docs.jfrog.com/artifactory/docs/distribution-through-cli#distributing-a-release-bundle
jf ds rbd "${RBv1_BUNDLE_NAME}" "${BUILD_ID}" --sync --create-repo --max-wait-minutes=30 --site="${JF_EDGE_NAME}"
set +e

sleep 10
# rm -f "${RBv1_SPEC_JSON}"


echo "\n *** Distribution: Query RBv1 bundle \n"
# ref: https://docs.jfrog.com/artifactory/reference/getreleasebundleversion
# jf curl distribution/api/v1/release_bundle/rbv1-spring-petclinic/cmd.2026-07-20-08-53
# curl --request GET --url https://psazuse.jfrog.io/distribution/api/v1/release_bundle/rbv1-spring-petclinic/cmd.2026-07-20-08-53/distribution --header 'Content-Type: application/json' --header "Authorization: Bearer ${PSAZUSE_JF_ACCESS_TOKEN}"
echo "\n *** Distribution: Query RBv1 bundle distribution \n"
export RB1_DISTRIBUTE_RESP_JSON="RB1_DISTRIBUTE-${BUILD_ID}.json"
curl --request GET --url "https://psazuse.jfrog.io/distribution/api/v1/release_bundle/${RBV1_BUNDLE_NAME}/${BUILD_ID}/distribution" --header 'Content-Type: application/json' --header "Authorization: Bearer ${PSAZUSE_JF_ACCESS_TOKEN}" > "${RB1_DISTRIBUTE_RESP_JSON}"

items=$(jq -c -r '.[].sites[].target_artifactory.name' "${RB1_DISTRIBUTE_RESP_JSON}")
for item in ${items}; do
  echo "${item}"
  if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    echo "   - [${item}.jfrog.io](https://${item}.jfrog.io) " >> "${GITHUB_STEP_SUMMARY}"
  fi
done


echo "\n Build Name: ${BUILD_NAME}   Build ID: ${BUILD_ID}  Release_BUNDLE_NAME: ${RBv1_BUNDLE_NAME} \n"

rm -f $RB1_DISTRIBUTE_RESP_JSON
rm -f $RB1_SPEC_JSON
jf -v

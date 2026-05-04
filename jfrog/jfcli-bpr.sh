
clear

export JF_NAME="psazuse" JFROG_CLI_LOG_LEVEL="DEBUG" PROJECT_KEY="ps-build-promote"
export JF_RT_URL="https://${JF_NAME}.jfrog.io" RT_REPO_VIRTUAL="bpr-spring-petclinic-mvn-virtual" RT_REPO_LOCAL_DEFAULT="bpr-spring-petclinic-mvn-init-local"
export RT_REPO_LOCAL_DEV="bpr-spring-petclinic-mvn-dev-local" RT_REPO_LOCAL_QA="bpr-spring-petclinic-mvn-qa-local"

export BUILD_NAME="spring-petclinic" BUILD_ID="cmd.$(date '+%Y-%m-%d-%H-%M')" 
export EVD_KEY_PRIVATE="$(cat ~/.ssh/jfrog_evd_private.pem)" EVD_KEY_ALIAS="KRISHNAM_JFROG_EVD_PUBLICKEY"


echo " ** Maven package **"
jf mvnc --global --repo-resolve-releases ${RT_REPO_VIRTUAL} --repo-resolve-snapshots ${RT_REPO_VIRTUAL} 
jf mvn clean install -DskipTests=true -Denforcer.skip=true --build-name="${BUILD_NAME}" --build-number="${BUILD_ID}" --detailed-summary=true --project="${PROJECT_KEY}"

sleep 2
echo "\n*** Build publish: ${BUILD_NAME}  ${BUILD_ID} \n"
jf rt bce ${BUILD_NAME} ${BUILD_ID} --project="${PROJECT_KEY}"
jf rt bp ${BUILD_NAME} ${BUILD_ID} --project="${PROJECT_KEY}"


echo " ** Evidence: Build Publish **"
# jf evd create --build-name="spring-petclinic" --build-number="cmd.2026-05-04-11-08" --predicate="./target/classes/META-INF/sbom/application.cdx.json" --predicate-type="https://cyclonedx.org/bom/v1.4" --key="$(cat ~/.ssh/jfrog_evd_private.pem)" --key-alias="KRISHNAM_JFROG_EVD_PUBLICKEY" --project="ps-build-promote"
jf evd create --build-name="${BUILD_NAME}" --build-number="${BUILD_ID}" --predicate="./target/classes/META-INF/sbom/application.cdx.json" --predicate-type="https://cyclonedx.org/bom/v1.4" --key="${EVD_KEY_PRIVATE}" --key-alias="${EVD_KEY_ALIAS}" --project="${PROJECT_KEY}"

export EVD_SPEC_BP_JSON="evd-spec-bp.json"
# echo '{"actor":"cmd","date":"'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'","result":"pass"}' > ./evd-spec-bp.json      # https://jfrog.com/evidence/build-signature/v1      https://jfrog.com/evidence/signature/v1
echo '{"actor":"cmd","date":"'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'","result":"pass"}' > ./${EVD_SPEC_BP_JSON}
# jf evd create --build-name="spring-petclinic" --build-number="cmd.2026-05-04-12-09" --predicate="./evd-spec-bp.json" --predicate-type="https://jfrog.com/evidence/build-signature/v1" --key="$(cat ~/.ssh/jfrog_evd_private.pem)" --key-alias="KRISHNAM_JFROG_EVD_PUBLICKEY" --project="ps-build-promote"
jf evd create --build-name="${BUILD_NAME}" --build-number="${BUILD_ID}" --predicate="./${EVD_SPEC_BP_JSON}" --predicate-type="https://jfrog.com/evidence/build-signature/v1" --key="${EVD_KEY_PRIVATE}" --key-alias="${EVD_KEY_ALIAS}" --project="${PROJECT_KEY}"

sleep 2
echo "\n*** Build Promote: Evidence approval DEV\n"
export EVD_SPEC_APPROVAL_DEV_JSON="evd-spec-approval-dev.json"
# echo '{"pipeline": "CMD SH", "evd": "Evidence-Approval-DEV", "actor": "dev-team", "action": "approved", "date": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"}' > ./evd-spec-approval-dev.json
echo '{"pipeline": "CMD SH", "evd": "Evidence-Approval-DEV", "actor": "dev-team", "action": "approved", "date": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"}' > ./${EVD_SPEC_APPROVAL_DEV_JSON}
# jf evd create --build-name="spring-petclinic" --build-number="cmd.2026-05-04-12-09" --predicate="./evd-spec-approval-dev.json" --predicate-type="https://jfrog.com/evidence/approval/v1" --key="$(cat ~/.ssh/jfrog_evd_private.pem)" --key-alias="KRISHNAM_JFROG_EVD_PUBLICKEY" --project="ps-build-promote"
# jf evd create --build-name="spring-petclinic" --build-number="cmd.2026-05-04-12-09" --predicate="./evd-spec-approval-dev.json" --predicate-type="https://jfrog.com/evidence/dev-approval/v1" --key="$(cat ~/.ssh/jfrog_evd_private.pem)" --key-alias="KRISHNAM_JFROG_EVD_PUBLICKEY" --project="ps-build-promote"
jf evd create --build-name="${BUILD_NAME}" --build-number="${BUILD_ID}" --predicate="./${EVD_SPEC_APPROVAL_DEV_JSON}" --predicate-type="https://jfrog.com/evidence/approval/v1" --key="${EVD_KEY_PRIVATE}" --key-alias="${EVD_KEY_ALIAS}" --project="${PROJECT_KEY}"

echo "\n*** Build Promote: SNAPSHOT to DEV\n"
# jf rt bpr spring-petclinic cmd.2026-03-19-10-52  --dry-run --source-repo=springpetclinic-mvn-dev-local --comment="Promoting build SNAPSHOT to DEV" --status
jf rt bpr ${BUILD_NAME} ${BUILD_ID} ${RT_REPO_LOCAL_DEV} --status="Promoting build SNAPSHOT to DEV" --project="${PROJECT_KEY}"

sleep 2
rm -rf ./${EVD_SPEC_BP_JSON}
rm -rf ./${EVD_SPEC_APPROVAL_DEV_JSON}
jf -v

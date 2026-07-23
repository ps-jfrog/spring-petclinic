
clear

export JF_NAME="psazuse" JFROG_CLI_LOG_LEVEL="DEBUG" 
export JF_RT_URL="https://${JF_NAME}.jfrog.io" PROJECT_KEY="ps-apptrust-rlm" APPLICATION_KEY="app-spring-petclinic"
export RT_REPO_VIRTUAL= "rbv2-spring-petclinic-mvn-virtual" # RT_REPO_LOCAL_DEFAULT="rbv2-spring-petclinic-mvn-init-local"
# RT_REPO_LOCAL_DEV="rbv2-spring-petclinic-mvn-dev-local" RT_REPO_LOCAL_QA="rbv2-spring-petclinic-mvn-qa-local"   RT_REPO_LOCAL_PROD="rbv2-spring-petclinic-mvn-prod-local"

export TIMESTAMP="$(date '+%Y.%m.%d-%H%M')"
export BUILD_NAME="spring-petclinic" BUILD_ID="cmd-at.${TIMESTAMP}" APPLICATION_VERSION="${TIMESTAMP}"
export EVD_KEY_PRIVATE="$(cat ~/.ssh/jfrog_evd_private.pem)" EVD_KEY_PUBLIC="$(cat ~/.ssh/jfrog_evd_public.pem)" EVD_KEY_ALIAS="KRISHNAM_JFROG_EVD_PUBLICKEY"

jf config use ${JF_NAME}

echo " ** Maven package **"
jf mvnc --global --repo-resolve-releases ${RT_REPO_VIRTUAL} --repo-resolve-snapshots ${RT_REPO_VIRTUAL}  \
  --repo-deploy-releases ${RT_REPO_VIRTUAL} --repo-deploy-snapshots ${RT_REPO_VIRTUAL} 
jf mvn clean install surefire-report:report -Denforcer.skip --build-name=${BUILD_NAME} --build-number=${BUILD_ID} \
 --project="${PROJECT_KEY}" --detailed-summary=true

sleep 2
echo "\n*** Build publish: ${BUILD_NAME}  ${BUILD_ID} \n"
jf rt bag ${BUILD_NAME} ${BUILD_ID} --project="${PROJECT_KEY}"
jf rt bce ${BUILD_NAME} ${BUILD_ID} --project="${PROJECT_KEY}"
jf rt bp ${BUILD_NAME} ${BUILD_ID} --project="${PROJECT_KEY}"

# ref: https://docs.jfrog.com/governance/docs/create-application-version-cli#example-2-create-an-application-version-using-a-spec-file
echo "\n*** AppTrust: App Version create **\n"
export AT_APP_SPEC_JSON="./at-app-spec.json"
cat > "${AT_APP_SPEC_JSON}" <<EOF
{
  "builds": [
    {
      "name": "${BUILD_NAME}",
      "number": "${BUILD_ID}",
      "repository_key": "${PROJECT_KEY}-build-info",
      "include_dependencies": false
    }
  ]
}
EOF
echo "AppTrust app spec file content: ${AT_APP_SPEC_JSON}"
cat ${AT_APP_SPEC_JSON}

# ref: https://docs.jfrog.com/governance/docs/create-application-version-cli 
# jf apptrust version-create "app-spring-petclinic" 2026.07.23-1225 --spec="./at-app-spec.json" 
jf apptrust version-create ${APPLICATION_KEY} ${APPLICATION_VERSION} --spec="${AT_APP_SPEC_JSON}" --tag="Package"
# jf apptrust version-create ${APPLICATION_KEY} ${APPLICATION_VERSION} --source-type-builds="name=${BUILD_NAME}, id=${BUILD_ID}, repository_key" --tag="prototype" --dry-run

echo "\n*** AppTrust: App Version GATE: before promote to DEV **\n"
# jf mvn test surefire-report:report -Denforcer.skip
# Convert Surefire reports: XML -> JSON (evidence predicate), HTML -> Markdown (UI summary via --markdown)
export JUNIT_TEST_RESULTS_JSON="./target/surefire-reports/test-results.json"
export JUNIT_TEST_RESULTS_HTML="./target/reports/surefire.html"
export JUNIT_TEST_RESULTS_MD="./target/reports/surefire.md"
./jfrog/convertXml2Json.sh "${JUNIT_TEST_RESULTS_JSON}"
./jfrog/convertReport2Md.sh "${JUNIT_TEST_RESULTS_HTML}" "${JUNIT_TEST_RESULTS_MD}"

export SBOM_FILE="./target/classes/META-INF/sbom/application.cdx.json"  PREDICATE_TYPE="https://cyclonedx.org/bom/v1.4" # https://docs.jfrog.com/governance/docs/evidence-payload
# jf evd create --application-key="app-spring-petclinic" --application-version="2026.07.23-1514" --predicate="./target/classes/META-INF/sbom/application.cdx.json" --predicate-type="https://cyclonedx.org/bom/v1.4" --key="$(cat ~/.ssh/jfrog_evd_private.pem)" --key-alias="KRISHNAM_JFROG_EVD_PUBLICKEY"
jf evd create --application-key="${APPLICATION_KEY}" --application-version="${APPLICATION_VERSION}" \
  --predicate="${SBOM_FILE}" --predicate-type="${PREDICATE_TYPE}" \
  --key="${EVD_KEY_PRIVATE}" --key-alias="${EVD_KEY_ALIAS}"

# --predicate must be JSON; --markdown is the human-readable Surefire report for the Evidence UI
# https://docs.jfrog.com/governance/docs/create-evidence-cli
export PREDICATE_TYPE="https://jfrog.com/evidence/test-results/v1"
jf evd create --application-key="${APPLICATION_KEY}" --application-version="${APPLICATION_VERSION}" \
  --predicate="${JUNIT_TEST_RESULTS_JSON}" --predicate-type="${PREDICATE_TYPE}" \
  --markdown="${JUNIT_TEST_RESULTS_MD}" \
  --key="${EVD_KEY_PRIVATE}" --key-alias="${EVD_KEY_ALIAS}"
sleep 2

# ref: https://docs.jfrog.com/governance/docs/promote-application-version-cli
echo "\n*** AppTrust: App Version promote to DEV **\n"

PREDICATE_JSON="approval-predicate.json" PREDICATE_TYPE="https://jfrog.com/evidence/approval/v1"
cat > "${PREDICATE_JSON}" <<EOF
{ 
  "actor": "krishna", 
  "pipeline": "CMD", 
  "build_name": "${BUILD_NAME}", 
  "build_id": "${BUILD_ID}", 
  "project": "${PROJECT_KEY}",
  "application_key": "${APPLICATION_KEY}",
  "application_version": "${APPLICATION_VERSION}",
  "evd": "Evidence-Approval"
}
EOF
cat ${PREDICATE_JSON}
jf evd create --application-key="${APPLICATION_KEY}" --application-version="${APPLICATION_VERSION}"  \
  --predicate="${PREDICATE_JSON}" --predicate-type="${PREDICATE_TYPE}"  \
  --key="${EVD_KEY_PRIVATE}" --key-alias="${EVD_KEY_ALIAS}" 
jf apptrust version-promote ${APPLICATION_KEY} ${APPLICATION_VERSION} DEV 

sleep 2

echo "\n*** AppTrust: App Version promote to QA **\n"
jf apptrust version-promote ${APPLICATION_KEY} ${APPLICATION_VERSION} QA
sleep 2

# ref: https://docs.jfrog.com/governance/docs/release-application-version-cli
echo "\n*** AppTrust: App Version promote to PROD **\n"
jf apptrust version-release ${APPLICATION_KEY} ${APPLICATION_VERSION}  


sleep 2
rm -rf ${AT_APP_SPEC_JSON}
rm -rf ${PREDICATE_JSON}

echo "\n PROJECT_KEY: ${PROJECT_KEY}  BUILD_NAME: ${BUILD_NAME}   BUILD_ID: ${BUILD_ID}  APPLICATION_KEY: ${APPLICATION_KEY}  APPLICATION_VERSION: ${APPLICATION_VERSION} \n"
jf -v

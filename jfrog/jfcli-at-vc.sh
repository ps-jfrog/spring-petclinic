
clear

export JF_NAME="psazuse" JF_EDGE_NAME="psazeuwedge" JFROG_CLI_LOG_LEVEL="DEBUG" 
export JF_RT_URL="https://${JF_NAME}.jfrog.io" PROJECT_KEY="ps-apptrust-rlm" APPLICATION_KEY="app-spring-petclinic"
export RT_REPO_VIRTUAL="rbv2-spring-petclinic-mvn-virtual" # RT_REPO_LOCAL_DEFAULT="rbv2-spring-petclinic-mvn-init-local"
# RT_REPO_LOCAL_DEV="rbv2-spring-petclinic-mvn-dev-local" RT_REPO_LOCAL_QA="rbv2-spring-petclinic-mvn-qa-local"   RT_REPO_LOCAL_PROD="rbv2-spring-petclinic-mvn-prod-local"

export TIMESTAMP="$(date '+%Y.%m.%d+%H%M')"
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


sleep 2
rm -rf ${AT_APP_SPEC_JSON}
rm -rf ${PREDICATE_JSON}

echo "\n PROJECT_KEY: ${PROJECT_KEY}  BUILD_NAME: ${BUILD_NAME}   BUILD_ID: ${BUILD_ID}  APPLICATION_KEY: ${APPLICATION_KEY}  APPLICATION_VERSION: ${APPLICATION_VERSION} \n"
jf -v


clear

export JF_NAME="psazuse" JFROG_CLI_LOG_LEVEL="DEBUG" 
export JF_RT_URL="https://${JF_NAME}.jfrog.io" PROJECT_KEY="ps-apptrust-rlm" APPLICATION_KEY="springpetclinic"
export RT_REPO_VIRTUAL= "rbv2-spring-petclinic-mvn-virtual" # RT_REPO_LOCAL_DEFAULT="rbv2-spring-petclinic-mvn-init-local"
# RT_REPO_LOCAL_DEV="rbv2-spring-petclinic-mvn-dev-local" RT_REPO_LOCAL_QA="rbv2-spring-petclinic-mvn-qa-local"   RT_REPO_LOCAL_PROD="rbv2-spring-petclinic-mvn-prod-local"

export BUILD_NAME="spring-petclinic" BUILD_ID="cmd-at.$(date '+%Y-%m-%d-%H-%M')" 

jf config use ${JF_NAME}

set -x  # debug mode ON
echo " ** Maven package **"
jf mvnc --global --repo-resolve-releases ${RT_REPO_VIRTUAL} --repo-resolve-snapshots ${RT_REPO_VIRTUAL} --repo-deploy-releases ${RT_REPO_VIRTUAL} --repo-deploy-snapshots ${RT_REPO_VIRTUAL} 
jf mvn clean install -DskipTests=true --build-name=${BUILD_NAME} --build-number=${BUILD_ID} --project="${PROJECT_KEY}" --detailed-summary=true

set +x  # debug mode OFF
sleep 2
echo "\n*** Build publish: ${BUILD_NAME}  ${BUILD_ID} \n"
jf rt bag ${BUILD_NAME} ${BUILD_ID} --project="${PROJECT_KEY}"
jf rt bce ${BUILD_NAME} ${BUILD_ID} --project="${PROJECT_KEY}"
jf rt bp ${BUILD_NAME} ${BUILD_ID} --project="${PROJECT_KEY}"

# ref: https://docs.jfrog.com/governance/docs/create-application-version-cli
# jf apptrust version-create "springpetclinic" "cmd-at.2026-07-21-10-16" --source-type-builds="name=spring-petclinic, id=cmd-at.2026-07-21-10-16" --tag="prototype" --dry-run
jf apptrust version-create ${APPLICATION_KEY} ${BUILD_ID} --source-type-builds="name=${BUILD_NAME}, id=${BUILD_ID}" --tag="prototype" --dry-run


sleep 2
rm -rf ${RBv2_SPEC_JSON}

echo "\n Build Name: ${BUILD_NAME}   Build ID: ${BUILD_ID}  RBv2_BUNDLE_NAME: ${RBv2_BUNDLE_NAME} \n"
jf -v

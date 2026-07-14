
clear

export JF_NAME="psazuse" JFROG_CLI_LOG_LEVEL="DEBUG" PROJECT_KEY="ps-build-promote"
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


echo "\n *** RLM: Create RBv2 and Distribute to SaaS Edge \n"
export RBv2_SPEC_JSON="rbv2-spec-info.json" RBv2_SIGNING_KEY="krishnam"
export RBv2_BUNDLE_NAME="rbv2-${BUILD_NAME}"
echo "{ \"files\": [ {\"build\": \"${BUILD_NAME}/${BUILD_ID}\", \"includeDeps\":\"true\", \"project\":\"${PROJECT_KEY}\"} ] }"  > ${RBv2_SPEC_JSON}
cat ${RBv2_SPEC_JSON}
# ref: https://docs.jfrog.com/governance/docs/release-lifecycle-management-cli#create-a-release-bundle-v2
jf rbc ${RBv2_BUNDLE_NAME} ${BUILD_ID} --sync=true --signing-key=${RBV2_SIGNING_KEY} --spec=${RBv2_SPEC_JSON} --project=${PROJECT_KEY}

# ref: https://docs.jfrog.com/governance/docs/release-lifecycle-management-cli#distribute-a-release-bundle-v2
jf rbd ${RBv2_BUNDLE_NAME} ${BUILD_ID} --sync=true --create-repo=true --project=${PROJECT_KEY} --site

# echo "\n*** Download RBv2 from SaaS Edge\n"
# jf rt dl --bundle ${{env.BUILD_NAME}}/${{env.BUILD_ID}} --detailed-summary=true --threads=100


sleep 2
rm -rf ${RBv2_SPEC_JSON}

echo "\n Build Name: ${BUILD_NAME}   Build ID: ${BUILD_ID}  RBv2_BUNDLE_NAME: ${RBv2_BUNDLE_NAME} \n"
jf -v

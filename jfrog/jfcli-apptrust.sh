
clear

export JF_NAME="psazuse" JFROG_CLI_LOG_LEVEL="DEBUG" 
export JF_RT_URL="https://${JF_NAME}.jfrog.io"  PROJECT_KEY="ps-apptrust-rlm"
export RT_REPO_VIRTUAL= "rbv2-spring-petclinic-mvn-virtual" # RT_REPO_LOCAL_DEFAULT="rbv2-spring-petclinic-mvn-init-local"
# RT_REPO_LOCAL_DEV="rbv2-spring-petclinic-mvn-dev-local" RT_REPO_LOCAL_QA="rbv2-spring-petclinic-mvn-qa-local"   RT_REPO_LOCAL_PROD="rbv2-spring-petclinic-mvn-prod-local"

export BUILD_NAME="spring-petclinic" BUILD_ID="cmd-at.$(date '+%Y-%m-%d-%H-%M')" 

jf config use ${JF_NAME}

set -x  # debug mode ON
echo " ** Maven package **"
jf mvnc --global --repo-resolve-releases ${RT_REPO_VIRTUAL} --repo-resolve-snapshots ${RT_REPO_VIRTUAL} --repo-deploy-releases ${RT_REPO_VIRTUAL} --repo-deploy-snapshots ${RT_REPO_VIRTUAL}
jf mvn clean install -DskipTests=true --build-name=${BUILD_NAME} --build-number=${BUILD_ID} --project="${PROJECT_KEY}" --detailed-summary=true
sleep 2
echo "\n*** Build publish: ${BUILD_NAME}  ${BUILD_ID} \n"
jf rt bag ${BUILD_NAME} ${BUILD_ID} --project="${PROJECT_KEY}"
jf rt bce ${BUILD_NAME} ${BUILD_ID} --project="${PROJECT_KEY}"
jf rt bp ${BUILD_NAME} ${BUILD_ID} --project="${PROJECT_KEY}"


echo "\n *** RLM: Create RBv2 \n"
export RBv2_SPEC_JSON="rbv2-spec-info.json" RBv2_SIGNING_KEY="krishnam"
export RBv2_BUNDLE_NAME="rbv2-${BUILD_NAME}"
echo "{ \"files\": [ {\"build\": \"${BUILD_NAME}/${BUILD_ID}\", \"includeDeps\":\"true\", \"project\":\"${PROJECT_KEY}\"} ] }"  > ${RBv2_SPEC_JSON}
cat ${RBv2_SPEC_JSON}
# ref: https://docs.jfrog.com/governance/docs/release-lifecycle-management-cli#create-a-release-bundle-v2
jf rbc ${RBv2_BUNDLE_NAME} ${BUILD_ID} --sync=true --signing-key=${RBV2_SIGNING_KEY} --spec=${RBv2_SPEC_JSON} --project=${PROJECT_KEY}

echo "\n*** RBv2 Promote: DEV\n"
jf rbp ${RBv2_BUNDLE_NAME} ${BUILD_ID} DEV --sync=true --signing-key=${RBV2_SIGNING_KEY} --project=${PROJECT_KEY}

echo "\n*** RBv2 Promote: QA\n"
jf rbp ${RBv2_BUNDLE_NAME} ${BUILD_ID} QA --sync=true --signing-key=${RBV2_SIGNING_KEY} --project=${PROJECT_KEY}

echo "\n*** RBv2 Promote: PROD\n"
jf rbp ${RBv2_BUNDLE_NAME} ${BUILD_ID} PROD --sync=true --signing-key=${RBV2_SIGNING_KEY} --project=${PROJECT_KEY}


# echo "\n - Distribute RBv2 to SaaS Edge \n"
# ref: https://docs.jfrog.com/governance/docs/release-lifecycle-management-cli#distribute-a-release-bundle-v2
#jf rbd ${RBv2_BUNDLE_NAME} ${BUILD_ID} --sync=true --create-repo=true --project=${PROJECT_KEY} --site

# echo "\n*** Download RBv2 from SaaS Edge\n"
# jf rt dl --bundle ${{env.BUILD_NAME}}/${{env.BUILD_ID}} --detailed-summary=true --threads=100

set +x  # debug mode OFF

sleep 2
rm -rf ${RBv2_SPEC_JSON}

echo "\n Build Name: ${BUILD_NAME}   Build ID: ${BUILD_ID}  RBv2_BUNDLE_NAME: ${RBv2_BUNDLE_NAME} \n"
jf -v

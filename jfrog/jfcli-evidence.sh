
clear

export JF_NAME="psazuse" JFROG_CLI_LOG_LEVEL="INFO" 
export JF_RT_URL="https://${JF_NAME}.jfrog.io" RT_REPO_VIRTUAL="springpetclinic-mvn-virtual" 
export RT_REPO_SNAPSHOT_LOCAL="springpetclinic-mvn-snapshot-local" RT_REPO_DEV_LOCAL="springpetclinic-mvn-dev-local"
export BUILD_NAME="spring-petclinic" BUILD_ID="cmd-evd.$(date '+%Y-%m-%d-%H-%M')" 

jf mvnc --global --repo-resolve-releases ${RT_REPO_VIRTUAL} --repo-resolve-snapshots ${RT_REPO_VIRTUAL} --repo-deploy-releases ${RT_REPO_VIRTUAL} --repo-deploy-snapshots ${RT_REPO_VIRTUAL}

jf mvn clean install -DskipTests=true --build-name ${BUILD_NAME} --build-number ${BUILD_ID} --detailed-summary=true

sleep 2
echo "\n*** Build publish: name: ${BUILD_NAME} ID: ${BUILD_ID} \n"
jf rt bce ${BUILD_NAME} ${BUILD_ID} 
jr rt bag ${BUILD_NAME} ${BUILD_ID} 
jf rt bp ${BUILD_NAME} ${BUILD_ID} --detailed-summary=true 

# BP evidence
export EVD_KEY_PRIVATE="$(cat ~/.ssh/jfrog_evd_private.pem)" EVD_KEY_PUBLIC="$(cat ~/.ssh/jfrog_evd_public.pem)" EVD_KEY_ALIAS="KRISHNAM_JFROG_EVD_PUBLICKEY" BP_EVIDENCE_SPEC_JSON="bp-evidence.json"

echo '{ "pipeline": "CMD SH", "evd": "Evidence-BuildPublish"}' > ./${BP_EVIDENCE_SPEC_JSON}
cat ./${BP_EVIDENCE_SPEC_JSON}
jf evd create --build-name ${BUILD_NAME} --build-number ${BUILD_ID} --predicate ./${BP_EVIDENCE_SPEC_JSON} --predicate-type https://jfrog.com/evidence/signature/v1 --key "${EVD_KEY_PRIVATE}" --key-alias "${EVD_KEY_ALIAS}"

rm -rf ./${BP_EVIDENCE_SPEC_JSON}


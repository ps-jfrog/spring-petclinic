
clear

export JF_NAME="psazuse" JFROG_CLI_LOG_LEVEL="DEBUG" 
export JF_RT_URL="https://${JF_NAME}.jfrog.io" RT_REPO_VIRTUAL="springpetclinic-mvn-virtual" 

export BUILD_NAME="spring-petclinic" BUILD_ID="aql.$(date '+%Y-%m-%d-%H-%M')" 

echo "Current directory: $(pwd)" 
cd ..
echo "Current directory: $(pwd)" 


def payload=[
release_bundle_name: {
  {
    "aql": [
      {
        "build": "${BUILD_NAME}/${BUILD_ID}",
        "includeDeps": "true",
        "props": ""
      }
    ]
  }
]

export VAR_RBv2_SPEC="RBv2-SPEC-${BUILD_ID}.json"  # ref: https://docs.jfrog-applications.jfrog.io/jfrog-applications/jfrog-cli/cli-for-jfrog-artifactory/using-file-specs
echo "{ \"aql\": [\"aql\": \"${BUILD_NAME}/${BUILD_ID}\", \"includeDeps\": \"true\", \"props\": \"\" } ] }"  > $VAR_RBv2_SPEC

jf rbc ${BUILD_NAME} ${BUILD_ID} --sync --access-token="${JF_ACCESS_TOKEN}" --url="${JF_RT_URL}" --signing-key="${RBv2_SIGNING_KEY}" --spec="${VAR_RBv2_SPEC}" --server-id="psazuse"

jf rbp --sync --access-token="${JF_ACCESS_TOKEN}" --url="${JF_RT_URL}" --signing-key="${RBv2_SIGNING_KEY}" --server-id="psazuse" ${BUILD_NAME} ${BUILD_ID} DEV  


# jf mvn test -Denforcer.skip

# echo "Current directory: $(pwd)" 


# ./jfrog/convertXml2Json.sh ../target/surefire-reports/test-results.json

# cat ../target/surefire-reports/test-results.json

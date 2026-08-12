
clear

export JF_NAME="psazuse" JF_EDGE_NAME="psazeuwedge" JFROG_CLI_LOG_LEVEL="DEBUG" 
export JF_RT_URL="https://${JF_NAME}.jfrog.io" PROJECT_KEY="ps-apptrust-rlm" 
export TIMESTAMP="$(date '+%Y.%m.%d+%H%M')" 
export APPLICATION_KEY="multi-apps" APPLICATION_VERSION="${TIMESTAMP}"
jf config use ${JF_NAME}


# ref: https://docs.jfrog.com/governance/docs/create-application-version-cli#example-2-create-an-application-version-using-a-spec-file
echo "\n*** AppTrust: App Version create **\n"
export AT_APP_SPEC_JSON="./at-app-spec.json"
cat > "${AT_APP_SPEC_JSON}" <<EOF
{
  "builds": [
    {
      "name": "spring-petclinic",
      "number": "cmd-at.2026.08.03+1234",
      "repository_key": "${PROJECT_KEY}-build-info",
      "include_dependencies": false
    },{
      "name": "spring-petclinic-rest",
      "number": "cmd-at.2026.08.03+1240",
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

# # # ref: https://docs.jfrog.com/governance/docs/promote-application-version-cli
# echo "\n*** AppTrust: App Version promote to DEV **\n"
# jf apptrust version-promote ${APPLICATION_KEY} ${APPLICATION_VERSION} DEV 
# sleep 2

# echo "\n*** AppTrust: App Version promote to QA **\n"
# jf apptrust version-promote ${APPLICATION_KEY} ${APPLICATION_VERSION} QA
# sleep 2

# set -o xtrace # DEBUG ON
# # ref: https://docs.jfrog.com/governance/docs/release-application-version-cli
# echo "\n*** AppTrust: App Version promote to PROD **\n"
# jf apptrust version-release ${APPLICATION_KEY} ${APPLICATION_VERSION}  

echo "\n PROJECT_KEY: ${PROJECT_KEY}  APPLICATION_KEY: ${APPLICATION_KEY}  APPLICATION_VERSION: ${APPLICATION_VERSION} \n"
rm -rf ${AT_APP_SPEC_JSON}
jf -v

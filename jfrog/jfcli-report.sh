
clear

export JF_NAME="psazuse" JFROG_CLI_LOG_LEVEL="DEBUG" 
export JF_RT_URL="https://${JF_NAME}.jfrog.io" RT_REPO_VIRTUAL="springpetclinic-mvn-virtual" 


export GIT_REPO_JSON="./frogbot-scanreport.json"

jf xr curl "/api/v1/git/repositories/60/commits/340a141eb05b5ef3c22eeb2a0b1fd8e36e569fd3/scan-results?branch_name=main" -H 'Content-Type: application/json' -o $GIT_REPO_JSON



# Get the count of SAST results
sast_count=$(cat "$GIT_REPO_JSON" | jq '.scan_results.sast | length')

if [ "$sast_count" -eq 0 ]; then
    echo "No SAST results found"
    exit 0
fi

echo "Found $sast_count SAST result(s):"


# Iterate through SAST results and print jfrog_severity, id, and file
cat "$GIT_REPO_JSON" | jq -r '.scan_results.sast[] | "\(.jfrog_severity)|\(.id)|\(.file)"' | while IFS='|' read -r severity id file; do
    echo "ID: $id   Severity: $severity   File: $file"
done



# # ps-jfrog/spring-petclinic.git
# export GIT_REPO_ID=$(cat $GIT_REPO_JSON | jq -r '.repositories[] | select(.url == "ps-jfrog/spring-petclinic.git") | .url')
# echo "GIT_REPO_ID: $GIT_REPO_ID"



# export GIT_REPO_COMMIT_HASH=$(git rev-parse HEAD)
# echo "GIT_REPO_COMMIT_HASH: $GIT_REPO_COMMIT_HASH"

# export GIT_REPO_COMMIT_HASH_SCAN_RESULTS_JSON="./GitRepoCommitHashScanResults-${{env.BUILD_ID}}.json"
# jf xr "/xray/api/v1/git/repositories/$GIT_REPO_ID/commits/$GIT_REPO_COMMIT_HASH/scan-results?branch_name=main" -H 'Content-Type: application/json' -o $GIT_REPO_COMMIT_HASH_SCAN_RESULTS_JSON
# cat $GIT_REPO_COMMIT_HASH_SCAN_RESULTS_JSON



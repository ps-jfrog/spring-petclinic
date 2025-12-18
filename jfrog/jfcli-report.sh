
clear

export JF_NAME="psazuse" JFROG_CLI_LOG_LEVEL="DEBUG" 
export JF_RT_URL="https://${JF_NAME}.jfrog.io" RT_REPO_VIRTUAL="springpetclinic-mvn-virtual" 


export GIT_REPO_PATH=$(git remote get-url origin)
export GIT_REPO_NAME="${GIT_REPO_PATH#git@github.com:}"
echo "GIT_REPO_NAME: $GIT_REPO_NAME"
export REPO_FULL_URL="https://github.com/${GIT_REPO_NAME}"

# Get the list of frogbot repositories
export GIT_REPO_JSON="./frogbot-repo.json"
jf xr curl "/api/v1/git/repositories" -H 'Content-Type: application/json' -o $GIT_REPO_JSON
REPO_COUNT=$(cat "$GIT_REPO_JSON" | jq '.repositories | length')

# Iterate through repositories
export REPO_ID=""
for i in $(seq 0 $((REPO_COUNT - 1))); do
    REPO_URL=$(jq -r ".repositories[$i].url" "$GIT_REPO_JSON")
    
    # Compare URL with REPO_FULL_URL
    if [ "$REPO_URL" == "$REPO_FULL_URL" ]; then
        export REPO_ID=$(jq -r ".repositories[$i].id" "$GIT_REPO_JSON")
        break
    fi
done

echo "Found repository ID: $REPO_ID for GIT_REPO_NAME: $GIT_REPO_NAME"

# repo vunerabilitiies
export GIT_REPO_VUNL_JSON="./frogbot-scanreport.json"
jf xr curl "/api/v1/git/repositories/$REPO_ID/commits/$(git rev-parse HEAD)/scan-results?branch_name=$(git branch --show-current)" -H 'Content-Type: application/json' -o $GIT_REPO_VUNL_JSON
# Get the count of SAST results
sast_count=$(cat "$GIT_REPO_VUNL_JSON" | jq '.scan_results.sast | length')

if [ "$sast_count" -eq 0 ]; then
    echo " - :no_good: :volcano: NO SAST results found" 
else
    echo "Found $sast_count SAST results"
    echo " | ID | JFrog Severity | File name | start line | abbreviation | description |" 
    echo " | :--- | :--- | :--- | :--- | :--- | :--- |"

    # Iterate through SAST results and print jfrog_severity, id, and file
    cat "$GIT_REPO_VUNL_JSON" | jq -r '.scan_results.sast[] | "\(.jfrog_severity)|\(.id)|\(.file)|\(.start_line)|\(.abbreviation)|\(.description)|"' | while IFS='|' read -r severity id file start_line abbreviation description; do
        echo " | $id | $severity | $file | $start_line | $abbreviation | $description |" 
    done
fi

rm -rf $GIT_REPO_JSON
rm -rf $GIT_REPO_VUNL_JSON
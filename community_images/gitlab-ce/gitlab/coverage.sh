#!/bin/bash

set -e
set -x

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

function test_gitlab() {
   NAMESPACE=$1
   # wait for the gitlab container to be up
   while ! docker-compose -p "$NAMESPACE" ps | grep -q -i -w "healthy"
      do
         sleep 3
         echo "waiting..."
      done

   # get the personal access token for gitlab access
   expires_at=$(date -d '+1 day' +%Y-%m-%d)
   access_token=$("$SCRIPTPATH"/gen_gitlab_token.py "testtoken" "$expires_at")

   # create a new project in the gitlab
   curl -k --request POST --header "PRIVATE-TOKEN: $access_token" \
    --header "Content-Type: application/json" \
    --data '{"name": "new_project", "description": "New Project", "initialize_with_readme": "true", "visibility": "public"}'\
     --url 'https://localhost:6643/api/v4/projects/'

   # clone the new project and make a test commit
   git -c http.sslVerify=false clone https://root:adminadmin@localhost:4443/root/new_project.git

   cd new_project
   echo "test commit" > test_file.txt
   git add test_file.txt
   git commit -m "update"
   git -c http.sslVerify=false push -u origin main

   # delete and reclone the project
   cd ..
   rm -rf new_project
   git -c http.sslVerify=false clone https://root:adminadmin@localhost:4443/root/new_project.git
   cd new_project
   if [ ! -f test_file.txt ]; then
      exit 1
   fi

   GITLAB_PORT=6643
   # run selenium tests
   "${SCRIPTPATH}"/../../common/selenium_tests/runner.sh localhost "${GITLAB_PORT}" "${SCRIPTPATH}"/selenium_tests "${NAMESPACE}" 2>&1
}

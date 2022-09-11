#!/bin/bash

set -e
set -x

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

function test_gitlab() {
   # get the personal access token for gitlab access
   expires_at=$(date -d '+1 day' +%Y-%m-%d)
   access_token=$("$SCRIPTPATH"/gen_gitlab_token.py "testtoken" "$expires_at")

   # create a new project in the gitlab
   curl -k --request POST --header "PRIVATE-TOKEN: $access_token" \
    --header "Content-Type: application/json" \
    --data '{"name": "new_project", "description": "New Project", "initialize_with_readme": "true", "visibility": "public"}'\
     --url 'https://localhost:4443/api/v4/projects/'

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
}

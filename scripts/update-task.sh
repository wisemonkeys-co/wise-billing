#!/bin/bash
# $1=REPO_TOKEN
# $2=OPERATION
# $3=ISSUE   
# $4=IMAGE 
# $5=TAG

# scripts/update-task.sh <token> add 122 ocs-app 1.0.0

ORGANIZATION=wisemonkeys-co 
PRODUCT=wise-billing
TMP_FILE="tmp/"$4"_"$3
                                                                                 
curl -H "Authorization: token $1" -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/$ORGANIZATION/$PRODUCT/issues/$3 | jq '.body' > $TMP_FILE

VALID=1
case $2 in
  add)
    echo -n "Adding service "$4
    sed "s/task-start)/task-start)\\\r\\\n- [ ] $4/" $TMP_FILE > $TMP_FILE"_body"
    ;;
  set)
    echo -n "Service "$4" done"
    sed "s/- \[ \] $4/- \[x\] $4/" $TMP_FILE > $TMP_FILE"_body"
    ;;
  del)
    echo -n "Removing service "$4
    sed "s/- \[ \] $4\\\r\\\n//1" $TMP_FILE |  sed "s/- \[x\] $4\\\r\\\n//1" > $TMP_FILE"_body"
    ;;
  unset)
    echo -n "Service "$4" undone"
    sed "s/- \[x\] $4/- \[ \] $4/" $TMP_FILE > $TMP_FILE"_body"
    ;;
  *)
    echo -n "Invalid operation"
    VALID=0
    ;;
esac

if [[ "$VALID" -eq 1 ]]
then
    BODY=$(cat $TMP_FILE"_body" )
    curl --request PATCH  -H "Authorization: token $1" -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/$ORGANIZATION/$PRODUCT/issues/$3 \
    -d '{"body":'"${BODY}"' }'
    echo $BODY
fi

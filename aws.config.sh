###########
# Script Config
###########

awsregion=<aws-region>
awsaccount=<aws-account-id>
apistage=<api-stage>
weborigin=http://localhost:8000
tablename=T_SF_Table_test
rolename=R_SF_Table_test
policyname=P_SF_Table_test
functionname=F_SF_Table_test
api=API_SF_Table_test
schema="<schema>"
authregion=<auth-aws-region>
authapi=<auth-api-id>
authstage=<auth-api-stage>
listadminonly=false
detailsadminonly=false
insertadminonly=true
updateadminonly=true
deleteadminonly=true
setschemaadminonly=true
getschemaadminonly=true

###########
# Script Config Ends
###########

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'
TBOLD=$(tput bold)
TNORMAL=$(tput sgr0)

INSTRUCTION=">> Instruction"
NEXTSTEPS=">> Next Steps"
NEXTSTEPSINSTRUCTION="š¬ Do what the instruction says, then come back here and run me again"
EXITMESSAGE="Exiting for now..."

echo -e "\nHello there! I will be guiding you today to complete the aws configuration. There are a few steps involved, but you needn't worry, I will do all the heavy lifting for you š. In between though, I will need some inputs from you and will need you to follow my instructions. Just stay with me and I think you'll be good!\n";

###########
# DyanmoDB Config
###########

echo -e "=============================="
echo -e "Step 1: DynamoDB Configuration"
echo -e "=============================="

echo -e "\n>> Table: ${TBOLD}$tablename${TNORMAL}";

echo -e "\nā³ Checking if ${TBOLD}$tablename${TNORMAL} exists"

tableexistscommand="aws dynamodb describe-table --table-name $tablename";

tableexists=`eval "$tableexistscommand | jq '.Table.TableArn'"`;

if [ -z "$tableexists" ]
then
      echo -e "\nš¬ Table ${TBOLD}$tablename${TNORMAL} does not exist ${YELLOW} ā  ${NC}, creating it";
      echo -e "\nā³ Creating table ${TBOLD}$tablename${TNORMAL} exists, moving ahead with it";
      newtable=`aws dynamodb create-table \
      --table-name $tablename \
      --attribute-definitions AttributeName=type,AttributeType=S AttributeName=id,AttributeType=N \
      --key-schema AttributeName=type,KeyType=HASH AttributeName=id,KeyType=RANGE \
      --provisioned-throughput ReadCapacityUnits=10,WriteCapacityUnits=5 | jq '.TableDescription.TableArn'`
      if [ -z "$newtable" ]
      then
            echo -e "\nš¬ DynamoDb table creation FAILED ${RED} x ${NC}";
      else
            echo -e "\nš¬ DynamoDb table creation SUCCESSFUL ${GREEN} ā ${NC}: $newtable";
      fi
else
      echo -e "\nš¬ Table ${TBOLD}$tablename${TNORMAL} exists, moving ahead with it ${GREEN} ā ${NC}";
      newtable="$tableexists";
fi

sleep 10

echo -e "\n>> Schema: ${TBOLD}$schema${TNORMAL}";

echo -e "\nā³ Creating admin ${TBOLD}$schema${TNORMAL}";

putitemschemacommand="aws dynamodb put-item --table-name $tablename --item '{ \"type\": {\"S\": \"schema\"}, \"id\": {\"N\": \"1\"}, \"value\": { \"S\": $schema } }' --return-consumed-capacity TOTAL --return-item-collection-metrics SIZE"

echo $putitemschemacommand;

putitemschema=`eval "$putitemschemacommand | jq '.ConsumedCapacity'"`;

if [ -z "$putitemschema" ]
then
      echo -e "\nš¬ Admin creation FAILED ${RED} x ${NC}";
else
      echo -e "\nš¬ Admin creation SUCCESSFUL ${GREEN} ā ${NC}: ${TBOLD}$schema${TNORMAL}";
fi

echo -e "\nš¬ DynamoDB configuration completed successfully for ${TBOLD}$tablename${TNORMAL} ${GREEN} ā ${NC}\n" 

echo -e "\nš¬ DynamoDB configuration completed successfully for ${TBOLD}$tablename${TNORMAL} ${GREEN} ā ${NC}\n" 

###########
# Lambda Function Config
###########

echo -e "====================================="
echo -e "Step 2: Lambda Function Configuration"
echo -e "====================================="

echo -e "\n\nStep 2a: Policy Configuration"
echo -e "-----------------------------"

echo -e "\n>> Policy: ${TBOLD}$policyname${TNORMAL}";

echo -e "\nā³ Checking if ${TBOLD}$policyname${TNORMAL} exists";

getpolicycommand="aws iam get-policy --policy-arn arn:aws:iam::$awsaccount:policy/$policyname"

getpolicy=`eval "$getpolicycommand | jq '.Policy.Arn'"`;
getpolicyversion=`eval "$getpolicycommand | jq '.Policy.DefaultVersionId'"`;

if [ -z "$getpolicy" ]
then
      echo -e "\nš¬ Policy ${GREEN} ā ${NC}: ${TBOLD}$policyname${TNORMAL} does not exist ${RED} x ${NC}";
      echo -e "\nā³ Creating policy ${TBOLD}$policyname${TNORMAL}";
      policydocument="{\"Version\": \"2012-10-17\", \"Statement\": [{\"Sid\": \"Stmt1674124196543\",\"Action\": \"dynamodb:*\",\"Effect\": \"Allow\",\"Resource\": ${newtable}}, {\"Sid\": \"VisualEditor0\",\"Effect\": \"Allow\",\"Action\": [\"ses:SendEmail\",\"ses:SendTemplatedEmail\",\"ses:SendRawEmail\"],\"Resource\": \"*\"}]}"
      policycommand="aws iam create-policy --policy-name $policyname --policy-document '$policydocument'";
      policy=`eval "$policycommand | jq '.Policy.Arn'"`;
      getpolicy="$policy";
      if [ -z "$policy" ]
      then
            echo -e "š¬ Policy creation FAILED ${RED} x ${NC}";
      else
            echo -e "š¬ Policy creation SUCCESSFUL ${GREEN} ā ${NC}: $policy";
      fi
else
      echo -e "\nš¬ Policy ${TBOLD}$policyname${TNORMAL} exists ${GREEN} ā ${NC}";
      echo -e "\nā³ Checking details of policy ${TBOLD}$policyname${TNORMAL}";
      getpolicyversioncommand="aws iam get-policy-version --policy-arn $getpolicy --version-id $getpolicyversion";
      getpolicyversion=`eval "$getpolicyversioncommand | jq '.PolicyVersion.Document'"`
      
      if [[ "$getpolicyversion" == *"dynamodb:*"* ]] && [[ "$getpolicyversion" == *"$newtable"* ]] && [[ "$getpolicyversion" == *"Allow"* ]]; then
            echo -e "\nš¬ Policy ${TBOLD}$policyname${TNORMAL} details look good ${GREEN} ā ${NC}";
      else 
            echo -e "\nš¬ Policy ${TBOLD}$policyname${TNORMAL} configuration is not according to the requirements ${RED} x ${NC}";
            echo -e "\n$INSTRUCTION"
            echo -e "š¬ Change the policy name at the top of the script" 
            echo -e "\n$NEXTSTEPS"
            echo -e "$NEXTSTEPSINSTRUCTION\n" 
            echo -e $EXITMESSAGE;
            exit 1;
      fi
      # deletepolicy=`eval "$deletepolicycommand"`
fi

sleep 5

echo -e "\n\nStep 2b: Role Configuration"
echo -e "---------------------------"

echo -e "\n>> Role: ${TBOLD}$rolename${TNORMAL}";

echo -e "\nā³ Checking if ${TBOLD}$rolename${TNORMAL} exists";

getrolecommand="aws iam get-role --role-name $rolename"

getrole=`eval "$getrolecommand | jq '.Role'"`;

if [ -z "$getrole" ]
then
      echo -e "\nš¬ Role ${GREEN} ā ${NC}: ${TBOLD}$rolename${TNORMAL} does not exist ${RED} x ${NC}";
      echo -e "\nā³ Creating role ${TBOLD}$rolename${TNORMAL}";
      rolecommand="aws iam create-role --role-name $rolename --assume-role-policy-document '{\"Version\": \"2012-10-17\",\"Statement\": [{ \"Effect\": \"Allow\", \"Principal\": {\"Service\": \"lambda.amazonaws.com\"}, \"Action\": \"sts:AssumeRole\"}]}'";

      role=`eval "$rolecommand" | jq '.Role.Arn'`;

      if [ -z "$role" ]
      then
            echo -e "\nš¬ Role creation FAILED ${RED} x ${NC}";
            exit;
      else
            echo -e "\nš¬ Role creation SUCCESSFUL ${GREEN} ā ${NC}: $role";
      fi

      echo -e "\nā³ Attaching policy to role ${TBOLD}$rolename${TNORMAL}";
      attachrolepolicycommand="aws iam attach-role-policy --role-name $rolename --policy-arn $getpolicy"
      attachrolepolicy=`eval "$attachrolepolicycommand"`;

      echo -e "\nš¬ Policy attach SUCCESSFUL ${GREEN} ā ${NC}: $rolename > $policyname";
      
else
      echo -e "\nš¬ Role ${TBOLD}$rolename${TNORMAL} exists ${GREEN} ā ${NC}";
      echo -e "\nā³ Checking details of role ${TBOLD}$rolename${TNORMAL}";
      
      role=`eval "$getrolecommand | jq '.Role.Arn'"`;

      if [[ "$getrole" == *"lambda.amazonaws.com"* ]] && [[ "$getrole" == *"sts:AssumeRole"* ]]; then
            echo -e "\nš¬ Role ${TBOLD}$rolename${TNORMAL} details look good ${GREEN} ā ${NC}";
            echo -e "\nā³ Checking policy of role ${TBOLD}$rolename${TNORMAL}";
            getrolepolicycommand="aws iam list-attached-role-policies --role-name $rolename";
            getrolepolicy=`eval "$getrolepolicycommand | jq '.AttachedPolicies | .[] | select(.PolicyName==\"$policyname\") | .PolicyName '"`;
            if [ -z "$getrolepolicy" ]
            then
                  echo -e "\nš¬ Role ${TBOLD}$rolename${TNORMAL} configuration is not according to the requirements ${RED} x ${NC}";
                  echo -e "\n$INSTRUCTION"
                  echo -e "š¬ Change the role name at the top of the script" 
                  echo -e "\n$NEXTSTEPS"
                  echo -e "$NEXTSTEPSINSTRUCTION\n" 
                  echo -e $EXITMESSAGE;
                  exit 1;
            else
                  echo -e "\nš¬ Role ${TBOLD}$rolename${TNORMAL} configuration is good ${GREEN} ā ${NC}";
            fi
            
      else 
            echo -e "\nš¬ Role ${TBOLD}$rolename${TNORMAL} configuration is not according to the requirements ${RED} x ${NC}";
            echo -e "\n$INSTRUCTION"
            echo -e "š¬ Change the role name at the top of the script" 
            echo -e "\n$NEXTSTEPS"
            echo -e "$NEXTSTEPSINSTRUCTION\n" 
            echo -e $EXITMESSAGE;
            exit 1;
      fi
fi

sleep 10

echo -e "\n\nStep 2c: Lambda Function Configuration"
echo -e "--------------------------------------"

echo -e "\n>> Function: ${TBOLD}$functionname${TNORMAL}";

echo -e "\nā³ Preparing function code ${TBOLD}$rolename${TNORMAL}";

rm -r aws_proc

cp -r aws aws_proc

find ./aws_proc -name '*.js' -exec sed -i -e "s|AWS_REGION|$awsregion|g" {} \;
find ./aws_proc -name '*.js' -exec sed -i -e "s|DB_TABLE_NAME|$tablename|g" {} \;
find ./aws_proc -name '*.js' -exec sed -i -e "s|AUTH_AWS_REGION|$authregion|g" {} \;
find ./aws_proc -name '*.js' -exec sed -i -e "s|AUTH_AWS_API|$authapi|g" {} \;
find ./aws_proc -name '*.js' -exec sed -i -e "s|AUTH_AWS_STAGE|$authstage|g" {} \;
find ./aws_proc -name '*.js' -exec sed -i -e "s|WEB_ORIGIN|$weborigin|g" {} \;
find ./aws_proc -name '*.js' -exec sed -i -e "s|LIST_ADMIN_ONLY_VAL|$listadminonly|g" {} \;
find ./aws_proc -name '*.js' -exec sed -i -e "s|DETAILS_ADMIN_ONLY_VAL|$detailsadminonly|g" {} \;
find ./aws_proc -name '*.js' -exec sed -i -e "s|INSERT_ADMIN_ONLY_VAL|$insertadminonly|g" {} \;
find ./aws_proc -name '*.js' -exec sed -i -e "s|UPDATE_ADMIN_ONLY_VAL|$updateadminonly|g" {} \;
find ./aws_proc -name '*.js' -exec sed -i -e "s|DELETE_ADMIN_ONLY_VAL|$deleteadminonly|g" {} \;
find ./aws_proc -name '*.js' -exec sed -i -e "s|SETSCHEMA_ADMIN_ONLY_VAL|$setschemaadminonly|g" {} \;
find ./aws_proc -name '*.js' -exec sed -i -e "s|GETSCHEMA_ADMIN_ONLY_VAL|$getschemaadminonly|g" {} \;

zip -r -j ./aws_proc/table.zip aws_proc/table/*

echo -e "\nā³ Checking if function ${TBOLD}$functionname${TNORMAL} exists";

getfunctioncommand="aws lambda get-function --function-name $functionname";

getfunction=`eval "$getfunctioncommand | jq '.Configuration.FunctionArn'"`;

if [ -z "$getfunction" ]
then
      echo -e "\nš¬ Function doesn't exist ${RED} x ${NC}: $functionname";
      echo -e "\nā³ Creating function ${TBOLD}$rolename${TNORMAL}";
      createfunctioncommand="aws lambda create-function --function-name $functionname --zip-file fileb://aws_proc/table.zip --handler index.handler --runtime nodejs18.x --timeout 30 --role $role"
      echo $createfunctioncommand;
      createfunction=`eval "$createfunctioncommand | jq '.FunctionArn'"`;
      getfunction="$createfunction";
      if [ -z "$createfunction" ]
      then
            echo -e "\nš¬ Function creation FAILED ${RED} x ${NC}";
            exit 1;
      else
            echo -e "\nš¬ Function creation SUCCESSFUL ${GREEN} ā ${NC}: $functionname";
      fi
else
      echo -e "\nš¬ Function exists ${GREEN} ā ${NC}: $functionname";
      # TODO: Update code zip
fi

echo -e "\nš¬ Lambda configuration completed successfully for ${TBOLD}$functionname${TNORMAL} ${GREEN} ā ${NC}\n" 

sleep 10

###########
# API Gateway Config
###########

# echo -e "================================="
# echo -e "Step 3: API Gateway Configuration"
# echo -e "================================="

echo -e "\n\nStep 3a: Create API"
echo -e "------------------"

echo -e "\nā³ Creating API Gateway";

createapicommand="aws apigateway create-rest-api --name '$api' --region $awsregion";

createapi=`eval "$createapicommand" | jq '.id'`;

if [ -z "$createapi" ]
then
      echo -e "API creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ API creation SUCCESSFUL ${GREEN} ā ${NC}: $createapi";
fi

echo -e "\nā³ Getting resource handle";

getresourcescommand="aws apigateway get-resources --rest-api-id $createapi --region $awsregion"

getresources=`eval "$getresourcescommand | jq '.items | .[] | .id'"`

echo -e "\nš¬ API resource obtained ${GREEN} ā ${NC}: $getresources";

echo -e "\n\nStep 3b: Insert"
echo -e "--------------"

echo -e "\nā³ Creating insert method";

createresourceinsertcommand="aws apigateway create-resource --rest-api-id $createapi --region $awsregion --parent-id $getresources --path-part insert";

createresourceinsert=`eval "$createresourceinsertcommand | jq '.id'"`

if [ -z "$createresourceinsert" ]
then
      echo -e "\nš¬ Insert resource creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ Insert resource creation SUCCESSFUL ${GREEN} ā ${NC}: $createresourceinsert";
fi

putmethodinsertcommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourceinsert --http-method POST --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethodinsert=`eval "$putmethodinsertcommand | jq '.httpMethod'"`

if [ -z "$putmethodinsert" ]
then
      echo -e "\nš¬ Insert method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\nš¬ Insert method creation SUCCESSFUL ${GREEN} ā ${NC}: $putmethodinsert";
fi


putmethodinsertoptionscommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourceinsert --http-method OPTIONS --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethodinsertoptions=`eval "$putmethodinsertoptionscommand | jq '.httpMethod'"`

if [ -z "$putmethodinsertoptions" ]
then
      echo -e "\nš¬ Insert options method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\nš¬ Insert options method creation SUCCESSFUL ${GREEN} ā ${NC}: $putmethodinsertoptions";
fi



echo -e "\nā³ Creating lambda integration";

putintegrationinsertcommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourceinsert --http-method POST --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationinsert=`eval "$putintegrationinsertcommand | jq '.passthroughBehavior'"`;

putintegrationinsertoptionscommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourceinsert --http-method OPTIONS --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationinsertoptions=`eval "$putintegrationinsertoptionscommand | jq '.passthroughBehavior'"`;

echo -e "\nā³ Adding lambda invoke permission";

random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissioninsertcommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/POST/insert\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissioninsert=`eval "$lambdaaddpermissioninsertcommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissioninsert" ]
then
      echo -e "\nš¬ Insert lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ Insert lambda invoke grant creation SUCCESSFUL ${GREEN} ā ${NC}: $lambdaaddpermissioninsert";
fi

random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissioninsertoptionscommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/OPTIONS/insert\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissioninsertoptions=`eval "$lambdaaddpermissioninsertoptionscommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissioninsertoptions" ]
then
      echo -e "\nš¬ Insert options lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ Insert options lambda invoke grant creation SUCCESSFUL ${GREEN} ā ${NC}: $lambdaaddpermissioninsert";
fi

echo -e "\n\nStep 3c: List"
echo -e "--------------"

echo -e "\nā³ Creating list method";

createresourcelistcommand="aws apigateway create-resource --rest-api-id $createapi --region $awsregion --parent-id $getresources --path-part list";

createresourcelist=`eval "$createresourcelistcommand | jq '.id'"`

if [ -z "$createresourcelist" ]
then
      echo -e "\nš¬ List resource creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ List resource creation SUCCESSFUL ${GREEN} ā ${NC}: $createresourcelist";
fi

putmethodlistcommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourcelist --http-method POST --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethodlist=`eval "$putmethodlistcommand | jq '.httpMethod'"`

if [ -z "$putmethodlist" ]
then
      echo -e "\nš¬ List method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\nš¬ List method creation SUCCESSFUL ${GREEN} ā ${NC}: $putmethodlist";
fi


putmethodlistoptionscommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourcelist --http-method OPTIONS --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethodlistoptions=`eval "$putmethodlistoptionscommand | jq '.httpMethod'"`

if [ -z "$putmethodlistoptions" ]
then
      echo -e "\nš¬ List options method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\nš¬ List options method creation SUCCESSFUL ${GREEN} ā ${NC}: $putmethodlistoptions";
fi



echo -e "\nā³ Creating lambda integration";

putintegrationlistcommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourcelist --http-method POST --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationlist=`eval "$putintegrationlistcommand | jq '.passthroughBehavior'"`;


putintegrationlistoptionscommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourcelist --http-method OPTIONS --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationlistoptions=`eval "$putintegrationlistoptionscommand | jq '.passthroughBehavior'"`;


echo -e "\nā³ Adding lambda invoke permission";

random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissionlistcommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/POST/list\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissionlist=`eval "$lambdaaddpermissionlistcommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissionlist" ]
then
      echo -e "\nš¬ List lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ List lambda invoke grant creation SUCCESSFUL ${GREEN} ā ${NC}: $lambdaaddpermissionlist";
fi

random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissionlistoptionscommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/OPTIONS/list\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissionlistoptions=`eval "$lambdaaddpermissionlistoptionscommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissionlistoptions" ]
then
      echo -e "\nš¬ List options lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ List options lambda invoke grant creation SUCCESSFUL ${GREEN} ā ${NC}: $lambdaaddpermissionlist";
fi




echo -e "\n\nStep 3d: Details"
echo -e "--------------"

echo -e "\nā³ Creating details method";

createresourcedetailscommand="aws apigateway create-resource --rest-api-id $createapi --region $awsregion --parent-id $getresources --path-part details";

createresourcedetails=`eval "$createresourcedetailscommand | jq '.id'"`

if [ -z "$createresourcedetails" ]
then
      echo -e "\nš¬ Details resource creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ Details resource creation SUCCESSFUL ${GREEN} ā ${NC}: $createresourcedetails";
fi

putmethoddetailscommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourcedetails --http-method POST --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethoddetails=`eval "$putmethoddetailscommand | jq '.httpMethod'"`

if [ -z "$putmethoddetails" ]
then
      echo -e "\nš¬ Details method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\nš¬ Details method creation SUCCESSFUL ${GREEN} ā ${NC}: $putmethoddetails";
fi


putmethoddetailsoptionscommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourcedetails --http-method OPTIONS --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethoddetailsoptions=`eval "$putmethoddetailsoptionscommand | jq '.httpMethod'"`

if [ -z "$putmethoddetailsoptions" ]
then
      echo -e "\nš¬ Details options method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\nš¬ Details options method creation SUCCESSFUL ${GREEN} ā ${NC}: $putmethoddetailsoptions";
fi


echo -e "\nā³ Creating lambda integration";

putintegrationdetailscommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourcedetails --http-method POST --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationdetails=`eval "$putintegrationdetailscommand | jq '.passthroughBehavior'"`;

putintegrationdetailsoptionscommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourcedetails --http-method OPTIONS --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationdetailsoptions=`eval "$putintegrationdetailsoptionscommand | jq '.passthroughBehavior'"`;


echo -e "\nā³ Adding lambda invoke permission";

random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissiondetailscommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/POST/details\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissiondetails=`eval "$lambdaaddpermissiondetailscommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissiondetails" ]
then
      echo -e "\nš¬ Details lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ Details lambda invoke grant creation SUCCESSFUL ${GREEN} ā ${NC}: $lambdaaddpermissiondetails";
fi


random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissiondetailsoptionscommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/OPTIONS/details\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissiondetailsoptions=`eval "$lambdaaddpermissiondetailsoptionscommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissiondetailsoptions" ]
then
      echo -e "\nš¬ Details options lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ Details options lambda invoke grant creation SUCCESSFUL ${GREEN} ā ${NC}: $lambdaaddpermissiondetailsoptions";
fi




echo -e "\n\nStep 3e: Update"
echo -e "--------------"

echo -e "\nā³ Creating update method";

createresourceupdatecommand="aws apigateway create-resource --rest-api-id $createapi --region $awsregion --parent-id $getresources --path-part update";

createresourceupdate=`eval "$createresourceupdatecommand | jq '.id'"`

if [ -z "$createresourceupdate" ]
then
      echo -e "\nš¬ Update resource creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ Update resource creation SUCCESSFUL ${GREEN} ā ${NC}: $createresourceupdate";
fi

putmethodupdatecommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourceupdate --http-method POST --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethodupdate=`eval "$putmethodupdatecommand | jq '.httpMethod'"`

if [ -z "$putmethodupdate" ]
then
      echo -e "\nš¬ Update method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\nš¬ Update method creation SUCCESSFUL ${GREEN} ā ${NC}: $putmethodupdate";
fi

putmethodupdateoptionscommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourceupdate --http-method OPTIONS --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethodupdateoptions=`eval "$putmethodupdateoptionscommand | jq '.httpMethod'"`

if [ -z "$putmethodupdateoptions" ]
then
      echo -e "\nš¬ Update options method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\nš¬ Update options method creation SUCCESSFUL ${GREEN} ā ${NC}: $putmethodupdateoptions";
fi


echo -e "\nā³ Creating lambda integration";

putintegrationupdatecommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourceupdate --http-method POST --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationupdate=`eval "$putintegrationupdatecommand | jq '.passthroughBehavior'"`;

putintegrationupdateoptionscommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourceupdate --http-method OPTIONS --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationupdateoptions=`eval "$putintegrationupdateoptionscommand | jq '.passthroughBehavior'"`;

echo -e "\nā³ Adding lambda invoke permission";

random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissionupdatecommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/POST/update\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissionupdate=`eval "$lambdaaddpermissionupdatecommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissionupdate" ]
then
      echo -e "\nš¬ Update lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ Update lambda invoke grant creation SUCCESSFUL ${GREEN} ā ${NC}: $lambdaaddpermissionupdate";
fi


random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissionupdateoptionscommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/OPTIONS/update\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissionupdateoptions=`eval "$lambdaaddpermissionupdateoptionscommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissionupdateoptions" ]
then
      echo -e "\nš¬ Update options lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ Update options lambda invoke grant creation SUCCESSFUL ${GREEN} ā ${NC}: $lambdaaddpermissionupdateoptions";
fi



echo -e "\n\nStep 4f: SetSchems"
echo -e "--------------"

echo -e "\nā³ Creating setschema method";

createresourcesetschemacommand="aws apigateway create-resource --rest-api-id $createapi --region $awsregion --parent-id $getresources --path-part setschema";

createresourcesetschema=`eval "$createresourcesetschemacommand | jq '.id'"`

if [ -z "$createresourcesetschema" ]
then
      echo -e "\nš¬ SetSchema resource creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ SetSchema resource creation SUCCESSFUL ${GREEN} ā ${NC}: $createresourcesetschema";
fi

putmethodsetschemacommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourcesetschema --http-method POST --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethodsetschema=`eval "$putmethodsetschemacommand | jq '.httpMethod'"`

if [ -z "$putmethodsetschema" ]
then
      echo -e "\nš¬ SetSchema method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\nš¬ SetSchema method creation SUCCESSFUL ${GREEN} ā ${NC}: $putmethodsetschema";
fi

putmethodsetschemaoptionscommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourcesetschema --http-method OPTIONS --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethodsetschemaoptions=`eval "$putmethodsetschemaoptionscommand | jq '.httpMethod'"`

if [ -z "$putmethodsetschemaoptions" ]
then
      echo -e "\nš¬ SetSchema options method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\nš¬ SetSchema options method creation SUCCESSFUL ${GREEN} ā ${NC}: $putmethodsetschemaoptions";
fi


echo -e "\nā³ Creating lambda integration";

putintegrationsetschemacommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourcesetschema --http-method POST --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationsetschema=`eval "$putintegrationsetschemacommand | jq '.passthroughBehavior'"`;

putintegrationsetschemaoptionscommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourcesetschema --http-method OPTIONS --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationsetschemaoptions=`eval "$putintegrationsetschemaoptionscommand | jq '.passthroughBehavior'"`;


echo -e "\nā³ Adding lambda invoke permission";

random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissionsetschemacommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/POST/setschema\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissionsetschema=`eval "$lambdaaddpermissionsetschemacommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissionsetschema" ]
then
      echo -e "\nš¬ SetSchema lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ SetSchema lambda invoke grant creation SUCCESSFUL ${GREEN} ā ${NC}: $lambdaaddpermissionsetschema";
fi


random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissionsetschemaoptionscommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/OPTIONS/setschema\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissionsetschemaoptions=`eval "$lambdaaddpermissionsetschemaoptionscommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissionsetschemaoptions" ]
then
      echo -e "\nš¬ SetSchema options lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ SetSchema options lambda invoke grant creation SUCCESSFUL ${GREEN} ā ${NC}: $lambdaaddpermissiondeleteoptions";
fi


echo -e "\n\nStep 4g: Delete"
echo -e "--------------"

echo -e "\nā³ Creating delete method";

createresourcedeletecommand="aws apigateway create-resource --rest-api-id $createapi --region $awsregion --parent-id $getresources --path-part delete";

createresourcedelete=`eval "$createresourcedeletecommand | jq '.id'"`

if [ -z "$createresourcedelete" ]
then
      echo -e "\nš¬ Delete resource creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ Delete resource creation SUCCESSFUL ${GREEN} ā ${NC}: $createresourcedelete";
fi

putmethoddeletecommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourcedelete --http-method POST --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethoddelete=`eval "$putmethoddeletecommand | jq '.httpMethod'"`

if [ -z "$putmethoddelete" ]
then
      echo -e "\nš¬ Delete method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\nš¬ Delete method creation SUCCESSFUL ${GREEN} ā ${NC}: $putmethoddelete";
fi

putmethoddeleteoptionscommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourcedelete --http-method OPTIONS --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethoddeleteoptions=`eval "$putmethoddeleteoptionscommand | jq '.httpMethod'"`

if [ -z "$putmethoddeleteoptions" ]
then
      echo -e "\nš¬ Delete options method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\nš¬ Delete options method creation SUCCESSFUL ${GREEN} ā ${NC}: $putmethoddeleteoptions";
fi


echo -e "\nā³ Creating lambda integration";

putintegrationdeletecommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourcedelete --http-method POST --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationdelete=`eval "$putintegrationdeletecommand | jq '.passthroughBehavior'"`;

putintegrationdeleteoptionscommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourcedelete --http-method OPTIONS --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationdeleteoptions=`eval "$putintegrationdeleteoptionscommand | jq '.passthroughBehavior'"`;


echo -e "\nā³ Adding lambda invoke permission";

random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissiondeletecommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/POST/delete\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissiondelete=`eval "$lambdaaddpermissiondeletecommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissiondelete" ]
then
      echo -e "\nš¬ Delete lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ Delete lambda invoke grant creation SUCCESSFUL ${GREEN} ā ${NC}: $lambdaaddpermissiondelete";
fi


random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissiondeleteoptionscommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/OPTIONS/delete\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissiondeleteoptions=`eval "$lambdaaddpermissiondeleteoptionscommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissiondeleteoptions" ]
then
      echo -e "\nš¬ Delete options lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ Delete options lambda invoke grant creation SUCCESSFUL ${GREEN} ā ${NC}: $lambdaaddpermissiondeleteoptions";
fi



echo -e "\n\nStep 4h: Get Schema"
echo -e "--------------"

echo -e "\nā³ Creating getschema method";

createresourcegetschemacommand="aws apigateway create-resource --rest-api-id $createapi --region $awsregion --parent-id $getresources --path-part getschema";

createresourcegetschema=`eval "$createresourcegetschemacommand | jq '.id'"`

if [ -z "$createresourcegetschema" ]
then
      echo -e "\nš¬ GetSchema resource creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ GetSchema resource creation SUCCESSFUL ${GREEN} ā ${NC}: $createresourcegetschema";
fi

putmethodgetschemacommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourcegetschema --http-method POST --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethodgetschema=`eval "$putmethodgetschemacommand | jq '.httpMethod'"`

if [ -z "$putmethodgetschema" ]
then
      echo -e "\nš¬ GetSchema method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\nš¬ GetSchema method creation SUCCESSFUL ${GREEN} ā ${NC}: $putmethodgetschema";
fi

putmethodgetschemaoptionscommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourcegetschema --http-method OPTIONS --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethodgetschemaoptions=`eval "$putmethodgetschemaoptionscommand | jq '.httpMethod'"`

if [ -z "$putmethodgetschemaoptions" ]
then
      echo -e "\nš¬ GetSchema options method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\nš¬ GetSchema options method creation SUCCESSFUL ${GREEN} ā ${NC}: $putmethodgetschemaoptions";
fi


echo -e "\nā³ Creating lambda integration";

putintegrationgetschemacommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourcegetschema --http-method POST --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationgetschema=`eval "$putintegrationgetschemacommand | jq '.passthroughBehavior'"`;

putintegrationgetschemaoptionscommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourcegetschema --http-method OPTIONS --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationgetschemaoptions=`eval "$putintegrationgetschemaoptionscommand | jq '.passthroughBehavior'"`;


echo -e "\nā³ Adding lambda invoke permission";

random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissiongetschemacommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/POST/getschema\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissiongetschema=`eval "$lambdaaddpermissiongetschemacommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissiongetschema" ]
then
      echo -e "\nš¬ GetSchema lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ GetSchema lambda invoke grant creation SUCCESSFUL ${GREEN} ā ${NC}: $lambdaaddpermissiongetschema";
fi


random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissiongetschemaoptionscommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/OPTIONS/getschema\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissiongetschemaoptions=`eval "$lambdaaddpermissiongetschemaoptionscommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissiongetschemaoptions" ]
then
      echo -e "\nš¬ GetSchema options lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ GetSchema options lambda invoke grant creation SUCCESSFUL ${GREEN} ā ${NC}: $lambdaaddpermissiongetschemaoptions";
fi




echo -e "\nā³ Deploying API Gateway function";

createdeploymentcommand="aws apigateway create-deployment --rest-api-id $createapi --stage-name $apistage --region $awsregion"

createdeployment=`eval "$createdeploymentcommand | jq '.id'"`

if [ -z "$createdeployment" ]
then
    echo -e "\nš¬ Auth deployment creation FAILED ${RED} x ${NC}";
else
    echo -e "\nš¬ Auth deployment creation SUCCESSFUL ${GREEN} ā ${NC}: $createdeployment";
fi


echo -e "Script Ended...\n";

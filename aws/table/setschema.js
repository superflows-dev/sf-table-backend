import { UpdateItemCommand,QueryCommand,GetItemCommand } from "@aws-sdk/client-dynamodb";
import { SendEmailCommand } from "@aws-sdk/client-ses";
import { ddbClient, TABLE_NAME, AUTH_REGION, AUTH_API, SETSCHEMA_ADMIN_ONLY } from "./ddbClient.js";
import { generateOTP } from './util.js';
import { getSchema } from './schema.js';
import { processAuthenticate } from './authenticate.js';

export const processSetSchema = async (event) => {
  
  if(AUTH_REGION.length > 0 && AUTH_API.length > 0) {
    
    if((event["headers"]["Authorization"]) == null) {
      return {statusCode: 400, body: { result: false, error: "Malformed headers!"}};
    }
    
    if((event["headers"]["Authorization"].split(" ")[1]) == null) {
      return {statusCode: 400, body: { result: false, error: "Malformed headers!"}};
    }
    
    var hAscii = Buffer.from((event["headers"]["Authorization"].split(" ")[1] + ""), 'base64').toString('ascii');
    
    if(hAscii.split(":")[1] == null) {
      return {statusCode: 400, body: { result: false, error: "Malformed headers!"}};
    }
    
    const email = hAscii.split(":")[0];
    const accessToken = hAscii.split(":")[1];
    
    if(email == "" || !email.match(/^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$/)) {
        return {statusCode: 400, body: {result: false, error: "Malformed headers!"}}
    }
    
    if(accessToken.length < 5) {
        return {statusCode: 400, body: {result: false, error: "Malformed headers!"}}
    }
    
    const authResult = await processAuthenticate(event["headers"]["Authorization"]);
    
    if(!authResult) {
      return authResult;
    }
    
    if(SETSCHEMA_ADMIN_ONLY) {
      if(!authResult.admin) {
        return {statusCode: 401, body: {result: false, error: "Unauthorized request!"}};
      }
    }
    
  }
  
  // body sanity check
  
  var body = null;
    
  try {
      body = JSON.parse(event.body);
  } catch (e) {
      return {statusCode: 400, body: { result: false, error: "Malformed body!"}};
  }
  
  // acquire schema
  
  var resultQuery = await getSchema();
    
  if(resultQuery.Items.length === 0) {
    return {statusCode: 500, body: { result: false, error: "Server Error!"}};
  }
  
  const jsonSchema = JSON.parse(resultQuery.Items[0].value.S);
  
  // get only 1 data item
  
  var queryParams = {
      TableName: TABLE_NAME,
      KeyConditionExpression: "#type1 = :s1",
      Limit: 1,
      ExpressionAttributeNames: {
        "#type1": "type"
      },
      ExpressionAttributeValues: {
        ":s1": { "S": "data" }
      }
  };
  
  var resultItems = []
  
  async function ddbQuery () {
    try {
      const data = await ddbClient.send (new QueryCommand(queryParams));
      resultItems = resultItems.concat((data.Items))
      if(data.LastEvaluatedKey != null) {
        queryParams.ExclusiveStartKey = data.LastEvaluatedKey;
        await ddbQuery();
      }
    } catch (err) {
      return err;
    }
  };
    
  await ddbQuery();
  
  // Check if new schema alters already existing fields
  
  if(resultItems.length > 0 && event.body.indexOf(resultQuery.Items[0].value.S) < 0) {
    return {statusCode: 409, body: { result: false, error: "This operation is not safe! Since database already contains records, existing schema fields cannot be altered."}};
  }
  
  var updateParams = {
      TableName: TABLE_NAME,
      Key: {
        type: { S: "schema" },
        id: {N: "1"}
      },
      UpdateExpression: "set #value1 = :schema1",
      ExpressionAttributeValues: {
        ":schema1" : {
          "S": event.body
        }
      },
      ExpressionAttributeNames: {
        "#value1" : "value"
      }
  };

  const ddbUpdate = async () => {
      try {
        const data = await ddbClient.send(new UpdateItemCommand(updateParams));
        return data;
      } catch (err) {
        console.log(err)
        return err;
      }
  };
  
  var resultUpdate = await ddbUpdate();
  
  return {statusCode: 200, body: {result: true}};

}
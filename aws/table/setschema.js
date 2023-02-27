import { UpdateItemCommand,ScanCommand,GetItemCommand } from "@aws-sdk/client-dynamodb";
import { SendEmailCommand } from "@aws-sdk/client-ses";
import { ddbClient, TABLE_NAME, AUTH_REGION, AUTH_API } from "./ddbClient.js";
import { generateOTP } from './util.js';
import { getSchema } from './getjsonschema.js';
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
    
    if(!authResult.result) {
      return authResult;
    }
    
    if(!authResult.admin) {
      return {statusCode: 401, body: {result: false, error: "Unauthorized request!"}};
    }
    
    
  }
  
  // body sanity check
  
  var body = null;
    
  try {
      body = JSON.parse(event.body);
  } catch (e) {
      return {statusCode: 400, body: { result: false, error: "Malformed body!"}};
  }
  
  
  var updateParams = {
      TableName: TABLE_NAME,
      Key: {
        id: {S: "schema"}
      },
      UpdateExpression: "set #schema1 = :schema1",
      ExpressionAttributeValues: {
        ":schema1" : {
          "S": event.body
        }
      },
      ExpressionAttributeNames: {
        "#schema1" : "schema"
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
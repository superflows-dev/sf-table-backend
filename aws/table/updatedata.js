import { UpdateItemCommand,QueryCommand,GetItemCommand } from "@aws-sdk/client-dynamodb";
import { SendEmailCommand } from "@aws-sdk/client-ses";
import { ddbClient, TABLE_NAME, AUTH_REGION, AUTH_API } from "./ddbClient.js";
import { generateOTP } from './util.js';
import { getSchema } from './getjsonschema.js';
import { processAuthenticate } from './authenticate.js';
import { processValidateJson } from './validatejson.js'

export const processUpdateData = async (event) => {
  
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
    
  }
  
   // body sanity check
  
  var id = "";
  var body = null;
    
  try {
      body = JSON.parse(event.body);
      id = (JSON.parse(event.body).id.trim());
  } catch (e) {
      return {statusCode: 400, body: { result: false, error: "Malformed body!"}};
  }
  
  if(id == "") {
      return {statusCode: 400, body: {result: false, error: "Id not valid!"}}
  }
  
  const valResult = await processValidateJson((body.data))
  
  if(!valResult) {
    return {statusCode: 400, body: { result: false, error: "Malformed body!"}};
  }
  
  var updateParams = {
      TableName: TABLE_NAME,
      Key: {
        id: {S: id + ""}
      },
      UpdateExpression: "set #data1 = :data1",
      ExpressionAttributeNames: {
        '#data1': 'data'
      },
      ExpressionAttributeValues: {
        ':data1': {
          S: JSON.stringify(body.data) + ''
        }
      }
  };
  
  console.log(updateParams);
  
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
  
  console.log('resultUpdate', resultUpdate);
  
  return {statusCode: 200, body: {result: true}};

}
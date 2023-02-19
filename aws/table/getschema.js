import { UpdateItemCommand,QueryCommand,GetItemCommand } from "@aws-sdk/client-dynamodb";
import { SendEmailCommand } from "@aws-sdk/client-ses";
import { ddbClient, TABLE_NAME, AUTH_REGION, AUTH_API, GETSCHEMA_ADMIN_ONLY } from "./ddbClient.js";
import { generateOTP } from './util.js';
import { getSchema } from './schema.js';
import { processAuthenticate } from './authenticate.js';

export const processGetSchema = async (event) => {
  
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
    
    if(GETSCHEMA_ADMIN_ONLY) {
      if(!authResult.admin) {
        return {statusCode: 401, body: {result: false, error: "Unauthorized request!"}};
      }
    }
    
  }
  
  // acquire schema
  
  var resultQuery = await getSchema();
    
  if(resultQuery.Items.length === 0) {
    return {statusCode: 500, body: { result: false, error: "Server Error!"}};
  }
  
  const jsonSchema = JSON.parse(resultQuery.Items[0].value.S);
  
  return {statusCode: 200, body: {result: true, value: jsonSchema}};

}
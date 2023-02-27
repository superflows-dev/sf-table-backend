import { UpdateItemCommand,QueryCommand,GetItemCommand } from "@aws-sdk/client-dynamodb";
import { SendEmailCommand } from "@aws-sdk/client-ses";
import { ddbClient, TABLE_NAME, AUTH_REGION, AUTH_API } from "./ddbClient.js";
import { generateOTP } from './util.js';
import { getSchema } from './getjsonschema.js';
import { processAuthenticate } from './authenticate.js';
import { processValidateJson } from './validatejson.js'

export const processGetData = async (event) => {
  
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
  
  var getParams = {
      TableName: TABLE_NAME,
      Key: {
        id: {S: id + ""}
      }
  };
  
  console.log(getParams);
  
  const ddbGet = async () => {
      try {
        const data = await ddbClient.send(new GetItemCommand(getParams));
        return data;
      } catch (err) {
        console.log(err)
        return err;
      }
  };
  
  var resultGet = await ddbGet();
  
  return {statusCode: 200, body: {result: resultGet.Item != null ? resultGet.Item : '[]'}};

}
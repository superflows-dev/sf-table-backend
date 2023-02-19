import { DeleteItemCommand,QueryCommand,GetItemCommand } from "@aws-sdk/client-dynamodb";
import { SendEmailCommand } from "@aws-sdk/client-ses";
import { ddbClient, TABLE_NAME, AUTH_REGION, AUTH_API, DELETE_ADMIN_ONLY } from "./ddbClient.js";
import { generateOTP } from './util.js';
import { getSchema } from './schema.js';
import { processAuthenticate } from './authenticate.js';

export const processDelete = async (event) => {
  
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
    
    if(DELETE_ADMIN_ONLY) {
      if(!authResult.admin) {
        return {statusCode: 401, body: {result: false, error: "Unauthorized request!"}};
      }
    }
    
  }
  
  var id = -1;
  var payload = null;
    
  try {
      id = parseInt(JSON.parse(event.body).id.trim());
  } catch (e) {
      return {statusCode: 400, body: { result: false, error: "Malformed body!"}};
  }
  
  if(id == null || id < 0 || typeof id != 'number') {
      return {statusCode: 400, body: {result: false, error: "Id not valid!"}}
  }
  
  var getParams = {
      TableName: TABLE_NAME,
      Key: {
        type: { S: "data" },
        id: {N: id + ""}
      },
  };
  
  async function ddbGet () {
      try {
        const data = await ddbClient.send(new GetItemCommand(getParams));
        return data;
      } catch (err) {
        return err;
      }
  };
  
  var resultGet = await ddbGet();
  
  if(resultGet.Item == null) {
  
      return {statusCode: 404, body: {result: false, error: "Item does not exist!"}}

  }
  
  var deleteParams = {
      TableName: TABLE_NAME,
      Key: {
        type: { S: "data" },
        id: {N: id + ""}
      }
  };

  const ddbDelete = async () => {
      try {
        const data = await ddbClient.send(new DeleteItemCommand(deleteParams));
        return data;
      } catch (err) {
        console.log(err)
        return err;
      }
  };
  
  var resultDelete = await ddbDelete();
  
  return {statusCode: 200, body: {result: true}};

}
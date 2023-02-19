import { UpdateItemCommand,QueryCommand,GetItemCommand } from "@aws-sdk/client-dynamodb";
import { SendEmailCommand } from "@aws-sdk/client-ses";
import { ddbClient, TABLE_NAME, AUTH_REGION, AUTH_API, UPDATE_ADMIN_ONLY } from "./ddbClient.js";
import { generateOTP } from './util.js';
import { getSchema } from './schema.js';
import { processAuthenticate } from './authenticate.js';

export const processUpdate = async (event) => {
  
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

    
    if(UPDATE_ADMIN_ONLY) {
      if(!authResult.admin) {
        return {statusCode: 401, body: {result: false, error: "Unauthorized request!"}};
      }
    }
    
  }
  
  var id = -1;
  var payload = null;
    
  try {
      id = parseInt(JSON.parse(event.body).id.trim());
      payload = JSON.parse(event.body).payload;
  } catch (e) {
      return {statusCode: 400, body: { result: false, error: "Malformed body!"}};
  }
  
  if(id == null || id < 0 || typeof id != 'number') {
      return {statusCode: 400, body: {result: false, error: "Id not valid!"}}
  }
  
  if(payload == null) {
      return {statusCode: 400, body: {result: false, error: "Payload not valid!"}}
  }
    
  var resultQuery = await getSchema();
    
  if(resultQuery.Items.length === 0) {
    return {statusCode: 500, body: { result: false, error: "Server Error!"}};
  }
  
  const jsonSchema = JSON.parse(resultQuery.Items[0].value.S);
  
  for(var i = 0; i < Object.keys(payload).length; i++) {
    
    if(!Object.keys(jsonSchema).includes(Object.keys(payload)[i])) {
      return {statusCode: 400, body: { result: false, error: "Malformed body!"}};
    }
    
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
  
  var updateExpression = 'set ';
  
  for(var i = 0; i < Object.keys(payload).length; i++) {
    updateExpression += ('#' + Object.keys(payload)[i] + '1 = :' + Object.keys(payload)[i] + '1, ')
  }
  
  updateExpression = updateExpression.substring(0, updateExpression.length - 2);
  
  var expressionAttributeNames = {};
  
  for(var i = 0; i < Object.keys(payload).length; i++) {
    expressionAttributeNames['#' + Object.keys(payload)[i] + '1'] = Object.keys(payload)[i];
  }
  
  var expressionAttributeValues = {};
  
  for(var i = 0; i < Object.keys(payload).length; i++) {
    
    var dict = {};
    dict[jsonSchema[Object.keys(payload)[i]]] = payload[Object.keys(payload)[i]] + "";
    expressionAttributeValues[':' + Object.keys(payload)[i] + '1'] = dict;
  }
  
  var updateParams = {
      TableName: TABLE_NAME,
      Key: {
        type: { S: "data" },
        id: {N: id + ""}
      },
      UpdateExpression: updateExpression,
      ExpressionAttributeValues: expressionAttributeValues,
      ExpressionAttributeNames: expressionAttributeNames
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
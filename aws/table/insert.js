import { PutItemCommand,QueryCommand,GetItemCommand } from "@aws-sdk/client-dynamodb";
import { SendEmailCommand } from "@aws-sdk/client-ses";
import { ddbClient, TABLE_NAME, AUTH_REGION, AUTH_API, INSERT_ADMIN_ONLY } from "./ddbClient.js";
import { generateOTP } from './util.js';
import { processAuthenticate } from './authenticate.js';

export const processInsert = async (event) => {
  
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
    
    if(INSERT_ADMIN_ONLY) {
      if(!authResult.admin) {
        return {statusCode: 401, body: {result: false, error: "Unauthorized request!"}};
      }
    }
    
  }
  
  try {
    JSON.parse(event.body)
  } catch (e) {
      return {statusCode: 400, body: { result: false, error: "Malformed body!"}};
  }
  
  var queryParams = {
      TableName: TABLE_NAME,
      KeyConditionExpression: "#type1 = :s1",
      ExpressionAttributeNames: {
        "#type1": "type"
      },
      ExpressionAttributeValues: {
        ":s1": { "S": "schema" }
      }
  };
  
  async function ddbQuery () {
      try {
        const data = await ddbClient.send (new QueryCommand(queryParams));
        return data;
      } catch (err) {
        return err;
      }
  };
  
  var resultQuery = await ddbQuery();
  
  if(resultQuery.Items.length === 0) {
    return {statusCode: 500, body: { result: false, error: "Server Error!"}};
  }
  
  const jsonSchema = JSON.parse(resultQuery.Items[0].value.S);
  
  for(var i = 0; i < Object.keys(jsonSchema).length; i++) {
    
    if(!Object.keys(jsonSchema).includes(Object.keys(JSON.parse(event.body))[i])) {
      return {statusCode: 400, body: { result: false, error: "Malformed body!"}};
    }
    
  }
  
  var item = {};
  item['type'] = {"S": "data"};
  item['id'] = {"N": new Date().getTime() + ""};
  for(var i = 0; i < Object.keys(JSON.parse(event.body)).length; i++) {
    var type = {};
    type[jsonSchema[Object.keys(JSON.parse(event.body))[i]]] = JSON.parse(event.body)[Object.keys(JSON.parse(event.body))[i]];
    item[Object.keys(JSON.parse(event.body))[i]] = type;
  }
  
  var setParams = {
      TableName: TABLE_NAME,
      Item: item
  };
  
  const ddbPut = async () => {
      try {
        const data = await ddbClient.send(new PutItemCommand(setParams));
        return data;
      } catch (err) {
        return err;
      }
  };
  
  const resultPut = await ddbPut();
  
  return {statusCode: 200, body: {result: true}};

}
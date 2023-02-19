import { DeleteItemCommand,QueryCommand,GetItemCommand } from "@aws-sdk/client-dynamodb";
import { SendEmailCommand } from "@aws-sdk/client-ses";
import { ddbClient, TABLE_NAME, AUTH_REGION, AUTH_API, DETAILS_ADMIN_ONLY } from "./ddbClient.js";
import { generateOTP } from './util.js';
import { getSchema } from './schema.js';
import { processAuthenticate } from './authenticate.js';

export const processDetails = async (event) => {
  
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
    
    if(DETAILS_ADMIN_ONLY) {
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
  
  // sanity
  
  var id = -1;
    
  try {
      id = parseInt(JSON.parse(event.body).id.trim());
  } catch (e) {
      return {statusCode: 400, body: { result: false, error: "Malformed body!"}};
  }
  
  if(id == null || id < 0 || typeof id != 'number') {
      return {statusCode: 400, body: {result: false, error: "Id not valid!"}}
  }
  
  // acquire schema
  
  var resultQuery = await getSchema();
    
  if(resultQuery.Items.length === 0) {
    return {statusCode: 500, body: { result: false, error: "Server Error!"}};
  }
  
  const jsonSchema = JSON.parse(resultQuery.Items[0].value.S);
  
  // get query
  
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
  
  var unmarshalledItem = {};
  for(var i = 0; i < Object.keys(resultGet.Item).length; i++) {
    unmarshalledItem[Object.keys(resultGet.Item)[i]] = resultGet.Item[Object.keys(resultGet.Item)[i]][Object.keys(resultGet.Item[Object.keys(resultGet.Item)[i]])[0]]
  }
  
  
  return {statusCode: 200, body: {result: true, data: {schema: jsonSchema, value: unmarshalledItem}}};

}
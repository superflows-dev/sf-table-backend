import { processSetSchema } from './setschema.js'
import { processGetSchema } from './getschema.js'
import { processUpdateData } from './updatedata.js'
import { processGetData } from './getdata.js'

import { origin } from "./ddbClient.js";

export const handler = async (event, context, callback) => {
    
    const response = {
      statusCode: 200,
      headers: {
        "Access-Control-Allow-Origin" : origin,
        "Access-Control-Allow-Methods": "*",
        "Access-Control-Allow-Headers": "Authorization, Access-Control-Allow-Origin, Access-Control-Allow-Methods, Access-Control-Allow-Headers, Access-Control-Allow-Credentials, Content-Type, isBase64Encoded, x-requested-with",
        "Access-Control-Allow-Credentials" : true,
        'Content-Type': 'application/json',
        "isBase64Encoded": false
      },
    };
    
    if(event["httpMethod"] == "OPTIONS") {
      callback(null, response);
      return;
    }
    
    switch(event["path"]) {
      
      case "/getschema":
        const resultGetSchema = await processGetSchema(event);
        response.body = JSON.stringify(resultGetSchema.body);
        response.statusCode = resultGetSchema.statusCode;
        break;
      
      case "/setschema":
        const resultSetSchema = await processSetSchema(event);
        response.body = JSON.stringify(resultSetSchema.body);
        response.statusCode = resultSetSchema.statusCode;
        break;
        
      case "/updatedata":
        const resultUpdateData = await processUpdateData(event);
        response.body = JSON.stringify(resultUpdateData.body);
        response.statusCode = resultUpdateData.statusCode;
        break;
        
      case "/getdata":
        const resultGetData = await processGetData(event);
        response.body = JSON.stringify(resultGetData.body);
        response.statusCode = resultGetData.statusCode;
        break;
        
      default:
        response.body = JSON.stringify({result: false, error: "Method not found"});
        response.statusCode = 404;
      
    }
    
    // response.body = JSON.stringify(event);
    
    callback(null, response);
    
}
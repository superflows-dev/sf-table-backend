import { UpdateItemCommand,QueryCommand,GetItemCommand } from "@aws-sdk/client-dynamodb";
import { SendEmailCommand } from "@aws-sdk/client-ses";
import { ddbClient, TABLE_NAME, AUTH_REGION, AUTH_API } from "./ddbClient.js";
import { generateOTP } from './util.js';
import { getSchema } from './getjsonschema.js';
import { processAuthenticate } from './authenticate.js';

export const processValidateJson = async (data) => {

  console.log('1', data);
  
  // acquire schema
  
  var resultQuery = await getSchema();
    
  if(resultQuery.Items.length === 0) {
    return {statusCode: 500, body: { result: false, error: "Server Error!"}};
  }
  
  const jsonSchema = JSON.parse(resultQuery.Items[0].schema.S);
  
  function validate(obj, schema, root) {
    
    // Check presence of keys in schema
      
    const keys = Object.keys(obj);
      
    for(var i = 0; i < keys.length; i++) {
      
      if(!schema.props.includes(keys[i])) {
        return false;
      }
      
    }
    
    // Check data types of keys with schema
    
    for(var i = 0; i < keys.length; i++) {
      
      var indexKey = schema.props.indexOf(keys[i])
      
      if(Array.isArray(obj[keys[i]])) {
        
        if(schema.types[indexKey] != "list") {
          return false;
        }
        
        for(var j = 0; j < obj[keys[i]].length; j++) {
          
          if(!validate(obj[keys[i]][j], root[schema.schemas[indexKey]], root)) {
            return false;
          }
        }
        
      } else {
        
        if(schema.types[indexKey] == "enum") {
          
          if(!root[schema.schemas[indexKey]].includes(obj[keys[i]])) {
            return false;
          } 
          
        } else if(schema.types[indexKey] == "object") {
          
          if(schema.schemas[indexKey] == "string") {
            
          } else {
            if(!validate(obj[keys[i]], root[schema.schemas[indexKey]], root)) {
              return false;
            } 
          }

        }
      }
      
    }
    
    return true;
    
  }
  
  const valResult = validate(data, jsonSchema.root, jsonSchema)
  
  
  return {statusCode: 200, body: {result: valResult}};

}
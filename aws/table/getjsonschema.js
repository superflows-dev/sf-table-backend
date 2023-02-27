import { PutItemCommand,QueryCommand,GetItemCommand } from "@aws-sdk/client-dynamodb";
import { SendEmailCommand } from "@aws-sdk/client-ses";
import { ddbClient, TABLE_NAME } from "./ddbClient.js";
import { generateOTP } from './util.js';


export const getSchema = async () => {
  
  
    var queryParams = {
        TableName: TABLE_NAME,
        KeyConditionExpression: "#id1 = :id1",
        ExpressionAttributeNames: {
          "#id1": "id"
        },
        ExpressionAttributeValues: {
          ":id1": { "S": "schema" }
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
    
    return resultQuery;
    

}
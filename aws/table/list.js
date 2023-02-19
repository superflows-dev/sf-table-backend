import { DeleteItemCommand,QueryCommand,GetItemCommand } from "@aws-sdk/client-dynamodb";
import { SendEmailCommand } from "@aws-sdk/client-ses";
import { ddbClient, TABLE_NAME, AUTH_REGION, AUTH_API, LIST_ADMIN_ONLY } from "./ddbClient.js";
import { generateOTP } from './util.js';
import { getSchema } from './schema.js';
import { processAuthenticate } from './authenticate.js';

export const processList = async (event) => {
  
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
    
    if(LIST_ADMIN_ONLY) {
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
  
  // acquire schema
  
  var resultQuery = await getSchema();
    
  if(resultQuery.Items.length === 0) {
    return {statusCode: 500, body: { result: false, error: "Server Error!"}};
  }
  
  const jsonSchema = JSON.parse(resultQuery.Items[0].value.S);
  
  // query records
  
  var queryParams = {
      TableName: TABLE_NAME,
      KeyConditionExpression: "#type1 = :s1",
      ExpressionAttributeNames: {
        "#type1": "type"
      },
      ExpressionAttributeValues: {
        ":s1": { "S": "data" }
      }
  };
  
  var resultItems = []
  
  async function ddbQuery () {
    try {
      const data = await ddbClient.send (new QueryCommand(queryParams));
      resultItems = resultItems.concat((data.Items))
      if(data.LastEvaluatedKey != null) {
        queryParams.ExclusiveStartKey = data.LastEvaluatedKey;
        await ddbQuery();
      }
    } catch (err) {
      return err;
    }
  };
    
  await ddbQuery();
  
  // unmarshall the records
  
  var unmarshalledItems = [];
  
  for(var i = 0; i < resultItems.length; i++) {
    var item = {};
    for(var j = 0; j < Object.keys(resultItems[i]).length; j++) {
      item[Object.keys(resultItems[i])[j]] = resultItems[i][Object.keys(resultItems[i])[j]][Object.keys(resultItems[i][Object.keys(resultItems[i])[j]])[0]];
    }
    unmarshalledItems.push(item);
  }
  
  // sort the items
  
  var resultItemsSorted = unmarshalledItems;
  
  if(body.sortKey != null) {
    
    if(Object.keys(jsonSchema).includes(body.sortKey)) {
    
      if(body.sortOrder != null) {
        
        if(body.sortOrder == "asc") {
          resultItemsSorted = resultItemsSorted.sort((a, b) => a[body.sortKey] > b[body.sortKey] ? 1: -1)  
        } else {
          resultItemsSorted = resultItemsSorted.sort((a, b) => b[body.sortKey] > a[body.sortKey] ? 1: -1)  
        }
        
      }
      
    }
    
  }
  
  // filter the items
  
  var resultItemsFiltered = resultItemsSorted;
  
  if(body.filterKey != null) {
    if(Object.keys(jsonSchema).includes(body.filterKey)) {
      if(body.filterString != null) {
        if(body.filterString.length > 1) {
          var resultArr = [];
          for(var i = 0; i < resultItemsFiltered.length; i++) {
            if(resultItemsFiltered[i][body.filterKey].toLowerCase().indexOf(body.filterString.toLowerCase()) >= 0) {
              resultArr.push(resultItemsFiltered[i]);
            }
          }
          resultItemsFiltered = resultArr;
        }
      }
    }
  }
  
  // slice the item set based on offset limit
  
  var resultItemsSliced = resultItemsFiltered;
  
  if(body.offset != null) {
    
    if(body.limit != null) {
      resultItemsSliced = resultItemsFiltered.slice(parseInt(body.offset), (parseInt(body.offset) + parseInt(body.limit)));
    } else {
      resultItemsSliced = resultItemsFiltered.slice(parseInt(body.offset));
    }
    
  }
  
  return {statusCode: 200, body: {result: true, data: {schema: jsonSchema, values: (resultItemsSliced)}}};

}
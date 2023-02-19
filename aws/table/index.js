import { processSignUp } from './signUp.js'
import { processSignIn } from './signIn.js'
import { processVerify } from './verify.js'
import { processValidate } from './validate.js'
import { processRefresh } from './refresh.js'
import { processResend } from './resend.js'
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
      
      case "/signup":
        const resultSignUp = await processSignUp(event);
        response.body = JSON.stringify(resultSignUp.body);
        response.statusCode = resultSignUp.statusCode;
        break;
        
      case "/signin":
        const resultSignIn = await processSignIn(event);
        response.body = JSON.stringify(resultSignIn.body);
        response.statusCode = resultSignIn.statusCode;
        break;
        
      case "/verify":
        const resultVerify = await processVerify(event);
        response.body = JSON.stringify(resultVerify.body);
        response.statusCode = resultVerify.statusCode;
        break;
        
      case "/validate":
        const resultValidate = await processValidate(event);
        response.body = JSON.stringify(resultValidate.body);
        response.statusCode = resultValidate.statusCode;
        break;
        
      case "/refresh":
        const resultRefresh = await processRefresh(event);
        response.body = JSON.stringify(resultRefresh.body);
        response.statusCode = resultRefresh.statusCode;
        if(resultRefresh.statusCode === 200) {
          response.headers["Set-Cookie"] = "refreshToken=" + resultRefresh.body.data.refreshToken.token + " expires=" + new Date(parseInt(resultRefresh.body.data.refreshToken.expiry)).toUTCString(); 
        }
        break;
        
      case "/resend":
        const resultResend = await processResend(event);
        response.body = JSON.stringify(resultResend.body);
        response.statusCode = resultResend.statusCode;
        break;
        
      default:
        response.body = JSON.stringify({result: false, error: "Method not found"});
        response.statusCode = 404;
      
      
    }
    
    // response.body = JSON.stringify(event);
    
    callback(null, response);
    
}
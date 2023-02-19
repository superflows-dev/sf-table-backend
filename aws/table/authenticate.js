import https from 'https';
import { AUTH_REGION, AUTH_API, AUTH_STAGE } from "./ddbClient.js";

export const processAuthenticate = async (authorization) => {
  
  let myPromise = new Promise(function(resolve, reject) {
    
    var options = {
       host: AUTH_API + '.execute-api.' + AUTH_REGION + '.amazonaws.com',
       port: 443,
       method: 'POST',
       path: '/' + AUTH_STAGE + '/validate',
       headers: {
          'Authorization': authorization
       }   
    };
    
    console.log('auth options', options);
      
    //this is the call
    var request = https.get(options, function(response){
      let data = '';
      response.on('data', (chunk) => {
          data = data + chunk.toString();
      });
    
      response.on('end', () => {
          const body = JSON.parse(data);
          console.log('success', body);
          resolve(body)
      });
    })
    
    request.on('error', error => {
      console.log('error', error)
      resolve(error);
    })
    
    request.end()
    
  });
  
  return myPromise;

}
const REGION = "us-east-1"; //e.g. "us-east-1"
const TABLE_NAME = "T_SF_Data_Model_test";
const AUTH_REGION = "us-east-1";
const AUTH_API = "AUTH_AWS_API";
const AUTH_STAGE = "AUTH_AWS_STAGE";
const origin = "WEB_ORIGIN";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
const ddbClient = new DynamoDBClient({ region: REGION });
export { ddbClient, TABLE_NAME, origin, AUTH_REGION, AUTH_API, AUTH_STAGE };
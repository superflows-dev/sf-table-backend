<img src="https://superflows-images.s3.ap-south-1.amazonaws.com/superflows_logo_gray_c2c.png" width="400"/>

# SfUserAuth Backend

> Backend of the SfUserAuth authentication module provided by Superflows.

<br />

[![NPM](https://img.shields.io/npm/v/sf-nav.svg)](https://www.npmjs.com/package/sf-nav) [![JavaScript Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](https://standardjs.com)

<br />

## Deployment Instructions

### 1. Sign In To AWS Admin Account

Sign in to the AWS console with your AWS admin account. Go to IAM &gt; Users.

![](https://cdn.hashnode.com/res/hashnode/image/upload/v1675740756118/7317f1c2-7e1a-43c9-86a0-50da14c22999.jpeg)

### 2. Add User &gt; Details

Click on **Add Users**. In the Specify user details step write the name as **SfUserAuthDemo**. Let the enable console access option remain unchecked. Do not select it.

![](https://cdn.hashnode.com/res/hashnode/image/upload/v1675741319879/e58f873e-c22b-4049-b311-8d8ad3ee0c94.jpeg)

Click Next.

### 3. Add User &gt; Permissions

On the set permission page, choose the '**Attach policies directly**' option. Permissions will then drop down below. From the list of permissions, search and attach the following permissions one by one:

* AmazonAPIGatewayAdministrator
    
* AmazonAPIGatewayInvokeFullAccess
    
* AmazonDynamoDBFullAccess
    
* AmazonS3FullAccess
    
* AmazonSESFullAccess
    
* IAMFullAccess
    

Do not set the permissions boundary. Leave it untouched.

![](https://cdn.hashnode.com/res/hashnode/image/upload/v1675742180784/8edcd410-ad9e-40f0-b8e2-1586e49a96a0.jpeg)

Your selection of permissions should look something similar to the above image.

Click **Next**.

### 4. Add User &gt; Review & Create

Review and confirm that you have attached the policies properly.

![](https://cdn.hashnode.com/res/hashnode/image/upload/v1675742623675/d7d9e874-f29a-4f8c-a360-a2a743e84523.jpeg)

Click **Create User**.

The user should get created successfully as shown in the image below:

![](https://cdn.hashnode.com/res/hashnode/image/upload/v1675742823509/bc9833d8-077d-44b5-b5c3-975b26895566.jpeg)

### 5. Create User Credentials

Click on the user. The user information would load. Then click on the '**Security Credentials**' tab.

![](https://cdn.hashnode.com/res/hashnode/image/upload/v1675766807506/e2524743-14df-40c1-9b49-23a9175d1a59.jpeg)

Since we haven't created any access keys yet, it will show '**No access keys**'. Go ahead and click on the '**Create access key**' button.

In step 1, choose the '**Command Line Interface (CLI)**' option and check the '**I understand**' checkbox.

![](https://cdn.hashnode.com/res/hashnode/image/upload/v1675767222642/674d88a7-5f08-4622-af19-3f1b49d2ae28.jpeg)

Click **Next**.

In step 2, insert the text '**Access key to setup the backend for SfUserAuthDemo**' in the description field.

![](https://cdn.hashnode.com/res/hashnode/image/upload/v1675770051889/42666eea-1b99-462c-bca4-5ecfdb58a142.jpeg)

Click on **Create access key**.

In step 3, retrieve your access key. Save your access key and secret in a secure location.

![](https://cdn.hashnode.com/res/hashnode/image/upload/v1675770416217/9f52524a-a42c-4932-bafb-540066919c48.jpeg)

> At this point, we have completed creating the credentials. Now let us use those credentials and set up the cloud shell.

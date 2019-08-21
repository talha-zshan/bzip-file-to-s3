# bzip-file-to-s3

Bash Script that uses awscli to download, bzip and reupload files in a folder on s3 bucket using aws lambda environment.
Lambda is triggered on a S3 PUT event notification.

KEY POINTS:
1) The bzip file is uploaded to the same path of the PUT event notification. 
2) The folder of the PUT event is the folder that is bzipped and uploaded.
3) The script first checks if specified upload path already contains a bzip file to avoid infinite trigger loop 
  (NOT RECOMMENDED => I only did this according to instructions provided to me)

  AWSCLI Layer used in this task provided by:
  https://github.com/gkrizek/bash-lambda-layer
  
  Check Out the following links if you want to learn how to use awscli on lambda with python:
  
  "How to use AWS CLI within a Lambda function (By Ilya Bezdelev)" 
  https://bezdelev.com/hacking/aws-cli-inside-lambda-layer-aws-s3-sync/
  
  "Running aws-cli Commands Inside An AWS Lambda Function (By Eric Hammond)"
  https://alestic.com/2016/11/aws-lambda-awscli/

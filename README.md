# LOG8415 TP3 - CI/CD setup
Automatic blue/green app deployment to AWS, TP3 project for LOG8415 2021.

This project creates an automatic push-to-deploy environment for deploying another application to AWS.
A simple application that is being deployed is available here: [LOG8415 TP3 - Simple AWS app](https://github.com/jesinmat/LOG8415_simple_aws_app), although any application can be used.

Initial setup and teardown are fully automated. Before deploying the infrastructure, ensure you have your AWS credentials set and the following dependencies installed:

- python3
- boto3
- jq
- AWS CLI

Clone this repository. If you want to deploy other application than the one provided, make sure it has `setup.sh` in its root directory that will handle both setup and launch of the application. Otherwise, fork TP3 -- Simple AWS app (above).

Rename `lambda/secrets-example.sh` to `lambda/secrets.sh` and update the following values:

- AWS\_SECRET\_KEY - Provide randomly generated hex string, 32 -- 64 characters.

- AWS\_EC2\_KEYPAIR - Your AWS keypair name. This keypair will be used to launch new EC2 instances.

- APPLICATION\_REPO - Repository URL of the deployed application.


Once this is done, run `deploy.sh` from the root of the repository. This setup might take several minutes. When the script finishes, additional instructions will be displayed. 

To delete everything, run `cleanup.sh`.
# My First terraform test with AWS
 
 This is my first test to experiment with Terraform in order to create an infrastructure on AWS.
 I use my local laptop environment to actually deploy the terraform for AWS.
 
 You need to create some AWS resources, manually, before starting:
 - One SSH key pair
 - One IAM role to associate with EC2 instances (find the name inside the terraform file)
 - One S3 bucket to save the Terraform state file
 - One DynamoDb table with "LockId" as primary key
 
 In addition, you need to change AWS region and profile properties, inside Terraform file (Terraform.tf)
 
 ```
Terraform init --> to initialized terraform project
Terraform plan --> to make sure everything is coded properly
Terraform apply --> to actually deploy the setup
Terraform destroy --> to clean up everything
```

****
I am not responsible for expensive billings on AWS, problems on your existing infrastructure,
thermonuclear war, or you getting fired because of mess up on AWS.

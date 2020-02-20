# My First terraform test with AWS
 
 This is a cool start point to experiment with Terraform in order to create an infrastructure on AWS. 
 
 Bisogna creare prima di procedere:
 - una coppia di chiavi ssh
 - un ruolo IAM da associare alle EC2
 - un bucket S3 per salvare i file di terraform
 - una tabella DynamoDb chiamata con chiave primaria "LockID"
 
 ```
Terraform init --> to initialized terraform project
Terraform plan --> to make sure everything is coded properly
Terraform apply --> to actually deploy the setup
Terraform destroy --> to clean up everything
```



****
I am not responsible for expensive billings on AWS, problems on your existing infrastructure,
thermonuclear war, or you getting fired because of mess up on AWS.
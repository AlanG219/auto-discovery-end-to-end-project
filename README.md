# auto-discovery-end-to-end-project
my personal end to end pet-clinic auto discovey project 

# First file- adding .gitignore file
Once the github repository is created the first file to be added is the .gitignore file. 
The file names mentioned in the .gitignore are ignored by git meaning when using "git add ." command
they are not included for the push as they are not required in the repo and can cause issues when 
pushed such as delay with bigger files.
![alt text](image.png)

# 2nd task- Configure AWS resources: EC2 instances, VPC, subnets, security groups, IAM roles, etc.
Modules will be used to structure this project. using modules in Terraform is a best practice for
structuring code, making it more maintainable, reusable, and easier to understand.
By breaking down the infrastructure into smaller, self-contained modules, we can keep the root
main.tf file concise and focused on high-level orchestration.
# Auto-discovery-end-to-end-project
My personal end to end pet-clinic auto discovey project 

# Project Overview

This project focuses on automating the process of continuous integration and delivery using a Jenkins pipeline. It eliminates manual steps by automating actions between staging and production environments. The pipeline sequence demonstrates continuous integration up to the staging phase and continuous delivery to the production environment. Additionally, it showcases the use of an Auto Scaling Group (ASG) to launch instances from the staging environment to the production setup.
# Key Features

Automated Deployment: Jenkins triggers Ansible playbooks to dynamically update IP addresses in the host inventory file whenever ASG modifies instances.
Continuous Delivery: The pipeline facilitates the deployment of Docker images as containers within the Docker host environment.
Vault Integration: All processes are initiated upon activating the vault component.

# Tools and Technologies

Terraform (IAC): For infrastructure automation and management.
Ansible: For configuration management and application deployment.
Vault: For secure storage of secrets and sensitive data.
SonarQube: For continuous inspection of code quality.
Jenkins: For automating the CI/CD pipeline.
New Relic: For monitoring application performance and infrastructure.
Slack: For team communication and notifications.
GitHub: For version control and collaboration.
Nexus: For repository management.
Docker Hub: For container image storage.
Amazon Web Services (AWS): For cloud infrastructure.
Visual Studio Code: For development and editing.

# Setting up github repository
A github repo is created for this project. Even though this is a solo project a testing branch is created so that 
code can be organized, tested and experimented outside of the main branch, once tested it is pushed to main.

# First file- adding .gitignore file
Once the github repository is created the first file to be added is the .gitignore file. 
The file names mentioned in the .gitignore are ignored by git meaning when using "git add ." command
they are not included for the push as they are not required in the repo, these are mostly auto generated files which
serve other purposes and can cause issues when pushed such as delay with bigger files.

# Project structure
Modules will be used to structure this project. using modules in Terraform is a best practice for
structuring code, making it more maintainable, reusable, and easier to understand.
By breaking down the infrastructure into smaller, self-contained modules, the root
main.tf file can be kept concise and focused on high-level orchestration.
For automation scripts in this project functions are used. Isolating tasks within functions makes
debugging easier. If an error occurs, we can quickly identify which function is responsible and address
it. Functions also make it easier to maintain and update the script since changes can be made in 
a localized manner without affecting the entire script. Scripts with functions are also generally more
readable. Each function performs a distinct task, which is clearly defined by its name and purpose.
This helps both the author and other developers quickly understand what the script does.

# Following modules added

# Keypair
Module folder created, Keypair folder added as first module and root main.tf created.
The first module to be added is the keypair, A folder named Keypair is created under module folder and the
main.tf, variable.tf and output.tf is added to it. The root main.tf is also created on the project path outside module folder.
The keypair main.tf contains the AWS resources, the output.tf contains
values assigned to these resources once created and the variable.tf contains variables that have their values 
assigned in the root main.tf which is outside the module folder.All module folders will follow this base pattern 
(main.tf,output.tf, variable.tf and root main.tf). For the keypair main.tf three resources are created. 1. It generates an RSA key pair,
2. The private key is stored locally with secure permissions, 3. The public key is uploaded to AWS to be used as an EC2 key pair.
This setup is used to ensure that the private key remains secure while the public key is made available for SSH access to AWS instances.

# Security groups 
The security group module is created to contain all the AWS security group resources required for this project. The inbound rules allow 
certain ports on each security group and only allow what is required and nothing else for each instance it references.

# Bastion host
Next the bastion host is worked on. A folder named bastion is created under module folder and the
main.tf, variable.tf and output.tf is added to it along with the automation script for the bastion 
ec2 instance, this instance will be used for ssh access to any instances using a private IP as they
cannot be accessed directly.

# Sonarqube
Sonarqube module is created next. It will be used for code analysis and to measure its quality and identify issues. SonarQube's Quality Gate 
feature is being used to enforce quality standards. If the code doesn't pass the Quality Gate, the pipeline stops, ensuring that only 
high-quality code proceeds through the pipeline. Along with sonarqube being installed in the sonarqube script Postgresql is being 
installed as a backend database for storing SonarQube's data. Nginx is also installed on the script to handle web traffic, provide SSL 
termination, and improve security. Along with the ec2 resource on main.tf an elb is also created to load balance traffic.

# Nexus
Nexus module is created. Nexus is being used as both a repository manager for storing build artifacts and as a Docker registry for
managing Docker images. Artifact Repository: It stores and manages versioned build artifacts like the .war file, ensuring that they are easily accessible for deployment or future builds.
Docker Registry: It manages Docker images, allowing them to be stored, versioned, and accessed across various environments. This centralization helps in consistent deployment and easy rollback in case of issues.

# Jenkins
Jenkins module is created. On the jenkins script docker is installed along with Jenkins. Docker is necessary to create these images directly on the Jenkins instance.
After building Docker images, Jenkins can use Docker to push these images to the Docker registry in Nexus which can then be used for deployment in various environments.
An application load balancer is also created on the main.tf to load balance traffic.

# Ansible
Ansible module is created next. Ansible is used to automate the deployment of the application to staging and production environments. It ensures consistent, repeatable, and automated deployments by executing predefined playbooks on the target servers via SSH. This setup helps streamline the deployment process, reduce errors, and maintain uniformity across different environments.

# New relic

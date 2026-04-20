# terraform-aws

## Description

Builds a highly available AWS infrastructure from Terraform for a PHP web application communicating with a database.

![infrastructure schema](./imgs/infrastructure-schema.jpg)

## Modules

| name | usage |
|------|-------|
| `vpc` | Creates the VPC, public subnets, private subnets, internet access, routing, and security groups |
| `s3` | Creates the S3 bucket and uploads the PHP application sources |
| `ec2_role_allow_s3` | Creates an EC2 IAM role and instance profile with access to the app bucket and AWS Secrets Manager |
| `rds` | Creates the MariaDB database and DB subnet group |
| `secrets_manager` | Stores the database connection information used by EC2 at boot time |
| `alb_asg` | Creates the application load balancer, target group, launch template, key pair, and auto scaling group |
| `cloudwatch_cpu_alarms` | Creates the scale-up and scale-down policies plus CPU alarms |

## Service Choices

### AWS Secrets Manager

Dans cette architecture Terraform, AWS Secrets Manager est utilisé pour stocker de manière sécurisée les informations de connexion à la base de données (hôte, nom de base, utilisateur et mot de passe) sous forme de JSON chiffré. Ce choix est justifié par plusieurs raisons:

- **Sécurité renforcée** : Les secrets sont chiffrés au repos et en transit, avec un contrôle d'accès granulaire via IAM. Contrairement à un stockage en dur dans le code ou les variables Terraform (risque de fuite), Secrets Manager permet une récupération programmatique sans exposer les valeurs sensibles.
- **Intégration native avec AWS** : Il s'intègre parfaitement avec EC2 (via le rôle IAM dans le module `ec2_role_allow_s3`), RDS et d'autres services AWS, facilitant l'automatisation (récupération via AWS CLI dans le user-data du Launch Template).
- **Fonctionnalités avancées** : Supporte la rotation automatique des secrets (utile pour les mots de passe DB), le versioning et l'audit via CloudTrail, ce qui est essentiel pour une infrastructure hautement disponible et conforme aux bonnes pratiques de sécurité.
- **Simplicité dans ce projet** : Évite la complexité d'une gestion manuelle des secrets tout en permettant une initialisation automatique des instances EC2 sans intervention humaine.

Ce service est adapté à un environnement cloud AWS, où la scalabilité et la sécurité sont prioritaires, sans ajouter de dépendances externes.

#### Courte Comparaison avec des Services Équivalents

| Service | Avantages | Inconvénients | Comparaison avec Secrets Manager |
|---------|-----------|---------------|----------------------------------|
| **AWS Systems Manager Parameter Store** | Moins cher pour des données non-sensibles ; supporte le chiffrement optionnel (KMS) ; intégré à AWS. | Moins sécurisé par défaut (pas de rotation automatique) ; limité à 10 Ko par paramètre. | Plus simple et économique pour des configs non-secrètes, mais Secrets Manager est préférable pour les mots de passe en raison de ses fonctionnalités de sécurité avancées. |
| **Azure Key Vault** (Microsoft) | Chiffrement fort, rotation automatique, intégration avec Azure AD et services comme VMs. | Lié à l'écosystème Azure ; coût plus élevé pour les appels fréquents. | Similaire en fonctionnalités, mais Secrets Manager offre une meilleure intégration avec EC2/RDS dans un environnement AWS pur. |
| **Google Cloud Secret Manager** (GCP) | Chiffrement automatique, versioning, et intégration avec GKE/Compute Engine. | Moins mature pour les rotations complexes ; dépend de GCP. | Comparable pour la sécurité, mais Secrets Manager est plus flexible pour les déploiements multi-régions AWS. |
| **HashiCorp Vault** (Open-source, multi-cloud) | Auto-hébergé, hautement personnalisable, supporte plusieurs backends (AWS, etc.) ; gratuit en open-source. | Nécessite une gestion supplémentaire (installation, maintenance) ; pas natif à AWS. | Plus flexible et économique pour des environnements hybrides, mais Secrets Manager est plus simple pour un usage AWS-only, évitant la surcharge opérationnelle. |

En résumé, Secrets Manager est optimal pour ce projet AWS-centric en raison de son équilibre entre sécurité, intégration et facilité d'utilisation. Si vous migrez vers un autre provider, Azure Key Vault ou GCP Secret Manager seraient des équivalents directs. Si vous avez besoin d'une solution multi-cloud, HashiCorp Vault pourrait être envisagé.

## How It Works

First, define the database password in `terraform.tfvars`:

```tfvars
db_password = "your-password"
```

Make sure your AWS credentials are configured in the shell before running Terraform. For example, use your lab session credentials or run `aws configure` if your environment expects static credentials.

Second, create your SSH key pair in the `keys` folder. For example:

```shell
ssh-keygen -t rsa

Generating public/private rsa key pair.
Enter file in which to save the key (/home/hatim/.ssh/id_rsa): ./keys/terraform
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
```

The default public key path is already configured in `vars.tf` as `keys/terraform.pub`. If you store the key elsewhere, update the `path_to_public_key` variable.

By default, the project creates its own EC2 IAM role and instance profile so the web instances can read from S3 and retrieve the database credentials from AWS Secrets Manager. If you need to reuse an existing profile instead, set `existing_instance_profile_name` in `terraform.tfvars`. In AWS Academy labs, use `LabInstanceProfile` only if it already has S3 and Secrets Manager access.

You can then launch the configuration with:

```shell
terraform init
terraform plan
terraform apply
```

Result:

```
...
...

Outputs:

alb_dns_name = [DNS OF YOUR ELB]
```

Finally, print the load balancer DNS name and open it in your browser:

```shell
terraform output -raw alb_dns_name
```

The infrastructure is organized in Terraform modules under `modules/`:
- `modules/vpc`
- `modules/s3`
- `modules/ec2_role_allow_s3`
- `modules/rds`
- `modules/secrets_manager`
- `modules/alb_asg`
- `modules/cloudwatch_cpu_alarms`

Then test the application from the ALB DNS name:

![result](./imgs/result.jpg)

---

## Suggested Procedure

Below are suggestions for the procedure to follow when creating the infrastructure.

### VPC

1. Create a VPC with an IPv4 CIDR block of `10.0.0.0/16`.
2. Create two public subnets on two different availability zones with IPv4 CIDR blocks `10.0.1.0/24` and `10.0.2.0/24`.
3. Create two private subnets on the same availability zones as the public subnets with IPv4 CIDR blocks `10.0.3.0/24` and `10.0.4.0/24`.
4. Create the Internet Gateway.
5. Create a static IP address with the Elastic IP service to attach to the NAT Gateway.
6. Create the NAT Gateway.
7. Create public and private route tables to associate with their respective subnets.
8. Create a destination route `0.0.0.0/0` to the Internet Gateway in the public route table.
9. Create a destination route `0.0.0.0/0` to the NAT Gateway in the private route table.

### S3 and IAM Role

1. Create an S3 bucket with a unique name and private access, then automatically upload the web application sources into it.
2. Create a role attached to EC2 services with access to the application S3 bucket and read access to the database secret stored in AWS Secrets Manager.
3. Create an instance profile to pass the role information created above to the EC2 instances when they start.

> You can use VPC Endpoints to connect to S3 using a private network instead of the internet. You also have the option to create a bastion host on a public subnet if you need SSH access to instances in private subnets.

### ELB and ASG

1. Create a Security Group for the ASG allowing only traffic from the ELB on port 80.
2. Create a Security Group for the ELB allowing only traffic from the internet on port 80.
3. Create a Target Group on port 80 to help the ELB route HTTP requests to the instances in the ASG.
4. Create the Application Load Balancer attached to the public subnets and ELB security group.
5. Create an HTTP Listener attached to the ELB and Target Group.
6. Create a Launch Template for the ASG specifying the AMI, instance type (`t2.micro`), instance profile, user-data, key pair, and security group for the web instances. The user-data pulls the PHP sources from S3, reads the DB credentials from AWS Secrets Manager, and initializes the schema from `articles.sql`.
7. Create the Auto Scaling Group attached to the private subnets, the target group, and the ELB health check.

> To have an EC2 instance ready during scale-up, you can choose between a custom AMI or a user-data bootstrap. This project uses user-data to show the bootstrapping steps explicitly.

### RDS

1. Create a Security Group allowing only traffic from the web instances on port `3306`.
2. Create a `mariadb` database using the RDS service. It should be attached to the private subnets and the DB security group. The current implementation uses `db.t3.micro`, `20` GiB storage, one day of backups, and Multi-AZ enabled.

### Secrets Manager

1. Create a secret in AWS Secrets Manager containing the database hostname, database name, username, and password.
2. Pass the secret ARN to the EC2/ASG module so the web instances can fetch the connection details during boot.

### CloudWatch Alarm

1. Create two Auto Scaling policies, one for scale-up and one for scale-down. The policies should use `ChangeInCapacity` with values of `1` and `-1`.
2. Create two CloudWatch alarms based on `CPUUtilization`: one to scale up at or above `80%`, and one to scale down below `5%`.

> You can go further by creating email notifications via SNS when one of the ASG policies is triggered.

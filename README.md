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

### Amazon VPC (Virtual Private Cloud)

Amazon VPC est utilisé pour créer un réseau isolé et sécurisé dans AWS, incluant des sous-réseaux publics/privés, des passerelles Internet/NAT, des tables de routage et des groupes de sécurité. Ce choix est justifié par :

- **Isolation et sécurité** : Permet de séparer les ressources (e.g., EC2 en privé, ALB en public) et contrôler le trafic via des règles précises.
- **Haute disponibilité** : Déploiement multi-AZ avec sous-réseaux dans différentes zones pour la résilience.
- **Intégration** : Base pour tous les autres services (RDS, ALB), facilitant la connectivité privée.
- **Simplicité** : Terraform automatise la création complète du réseau, évitant les configurations manuelles.

#### Comparaison

| Service | Avantages | Inconvénients | Comparaison avec VPC |
|---------|-----------|---------------|----------------------|
| **Azure Virtual Network** | Intégration forte avec Azure AD ; support VNet peering. | Moins flexible pour les configurations avancées sans templates. | Similaire pour l'isolation, mais VPC offre plus de granularité dans les règles de sécurité. |
| **Google Cloud VPC** | Routage automatique ; intégration avec GKE. | Moins mature pour les environnements hybrides. | Comparable, mais VPC est plus intégré aux services AWS comme EC2/RDS. |
| **Open-source (e.g., Calico)** | Gratuit et personnalisable pour Kubernetes. | Nécessite une gestion manuelle ; pas natif cloud. | Plus flexible pour multi-cloud, mais VPC est plus simple pour AWS pur. |

### Amazon S3 (Simple Storage Service)

Amazon S3 stocke et sert les sources de l'application PHP de manière statique et sécurisée. Justifications :

- **Durabilité et scalabilité** : Stockage objet hautement durable (99.999999999%) et évolutif sans limites.
- **Sécurité** : Accès privé via IAM, avec chiffrement automatique.
- **Intégration** : Sync automatique depuis Terraform et récupération par EC2 via user-data.
- **Coût** : Pay-as-you-go, idéal pour des assets statiques.

#### Comparaison

| Service | Avantages | Inconvénients | Comparaison avec S3 |
|---------|-----------|---------------|---------------------|
| **Azure Blob Storage** | Intégration avec Azure Functions ; tiers froid/chaud. | Moins d'options de classes de stockage. | Similaire en durabilité, mais S3 offre plus de flexibilité pour les accès fréquents. |
| **Google Cloud Storage** | Forte intégration avec BigQuery ; versioning avancé. | Coûts plus élevés pour les transferts. | Comparable, mais S3 est plus mature pour les déploiements globaux. |
| **MinIO** (Open-source) | Auto-hébergé ; compatible S3 API. | Gestion manuelle requise. | Économique pour on-prem, mais S3 est plus fiable et sans maintenance. |

### Amazon EC2 (avec IAM Roles)

Amazon EC2 fournit les instances de calcul via Auto Scaling Groups (ASG), avec des rôles IAM pour l'accès sécurisé. Justifications :

- **Scalabilité** : ASG ajuste automatiquement le nombre d'instances basé sur la charge (CPU).
- **Sécurité** : Rôles IAM évitent les clés statiques ; accès limité à S3/Secrets Manager.
- **Flexibilité** : Instances t2.micro économiques, avec user-data pour bootstrap.
- **Haute disponibilité** : Multi-AZ via ASG.

#### Comparaison

| Service | Avantages | Inconvénients | Comparaison avec EC2 |
|---------|-----------|---------------|----------------------|
| **Azure VMs** | Intégration avec Azure AD ; support Windows/Linux. | Moins d'options de types d'instances. | Similaire pour la scalabilité, mais EC2 offre plus de diversité d'AMIs. |
| **Google Compute Engine** | Prépayé flexible ; intégration GKE. | Moins mature pour les workloads legacy. | Comparable, mais EC2 est plus intégré aux services AWS comme ALB. |
| **AWS Lambda** | Serverless ; pas de gestion d'instances. | Limité aux runtimes supportés. | Plus économique pour event-driven, mais EC2 est nécessaire pour des apps PHP persistantes. |

### Amazon RDS (Relational Database Service)

Amazon RDS gère la base de données MariaDB avec Multi-AZ pour la haute disponibilité. Justifications :

- **Gestion simplifiée** : Automatisation des backups, patches et scalabilité.
- **Haute disponibilité** : Multi-AZ pour failover automatique.
- **Sécurité** : Chiffrement, accès via VPC privé.
- **Performance** : Instance db.t3.micro adaptée au projet.

#### Comparaison

| Service | Avantages | Inconvénients | Comparaison avec RDS |
|---------|-----------|---------------|----------------------|
| **Azure Database for MySQL** | Intégration Azure AD ; scaling automatique. | Moins d'options de moteurs DB. | Similaire en gestion, mais RDS offre plus de flexibilité pour les migrations. |
| **Google Cloud SQL** | Intégration BigQuery ; backups automatiques. | Coûts plus élevés pour les instances. | Comparable, mais RDS est plus robuste pour les workloads critiques. |
| **Self-hosted MySQL** | Contrôle total ; gratuit. | Gestion manuelle (backups, sécurité). | Plus flexible, mais RDS évite la surcharge opérationnelle. |

### Amazon ALB (Application Load Balancer)

Amazon ALB distribue le trafic HTTP vers les instances EC2 de manière équilibrée. Justifications :

- **Équilibrage avancé** : Routage basé sur le contenu (paths, headers).
- **Haute disponibilité** : Multi-AZ, health checks automatiques.
- **Sécurité** : Intégration avec WAF ; trafic public sécurisé.
- **Scalabilité** : S'adapte à la charge sans intervention.

#### Comparaison

| Service | Avantages | Inconvénients | Comparaison avec ALB |
|---------|-----------|---------------|----------------------|
| **Azure Load Balancer** | Intégration Azure VMs ; support TCP/UDP. | Moins avancé pour HTTP. | Bon pour TCP, mais ALB excelle dans le routage applicatif. |
| **Google Cloud Load Balancing** | Global ; intégration GKE. | Plus complexe à configurer. | Comparable en scalabilité, mais ALB est plus simple pour AWS. |
| **NGINX** (Open-source) | Gratuit ; hautement personnalisable. | Gestion manuelle requise. | Flexible, mais ALB offre haute disponibilité sans maintenance. |

### Amazon CloudWatch

Amazon CloudWatch surveille les métriques (CPU) et déclenche des alarmes pour le scaling. Justifications :

- **Monitoring intégré** : Métriques natives d'EC2/ASG sans setup.
- **Automatisation** : Alarmes déclenchent des politiques de scaling.
- **Alertes** : Notifications possibles via SNS (non implémenté ici).
- **Coût** : Gratuit pour les métriques de base.

#### Comparaison

| Service | Avantages | Inconvénients | Comparaison avec CloudWatch |
|---------|-----------|---------------|-----------------------------|
| **Azure Monitor** | Intégration Azure AD ; dashboards avancés. | Moins granulaire pour les métriques custom. | Similaire, mais CloudWatch est plus intégré aux services AWS. |
| **Google Cloud Monitoring** | Intégration Stackdriver ; alerting avancé. | Coûts pour les métriques custom. | Comparable, mais CloudWatch est plus économique pour les bases. |
| **Prometheus** (Open-source) | Gratuit ; extensible. | Configuration manuelle. | Plus flexible, mais CloudWatch est plus simple pour AWS. |

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

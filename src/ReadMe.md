Cette application codée en php permet tout simplement de poster un article qui est ensuite sauvegardé sur notre base de données mysql. Voici quelques indications sur deux fichiers sources qui vous devez obligatoirement prendre en considération :

db-config.php : contient la configuration requise pour que votre application communique avec votre base de données, vous retrouverez :
##DB_HOST## : à remplacer par l'ip ou le nom dns de votre base de données.
##DB_USER## : à remplacer par le nom d'utilisateur de votre base de données.
##DB_PASSWORD## : à remplacer par le mot de passe utilisateur de votre base de données.
articles.sql : contient la requête SQL à exécuter pour créer l'architecture de votre table dans votre base de données.

Informations importantes avant de commencer , je vous demanderai de créer vos ressources Terraform sous forme de modules 

Vous pouvez cette utilisé cette arboressence 
├── modules/
│   ├── alb_asg/
│   ├── cloudwatch_cpu_alarms/
│   ├── ec2_role_allow_s3/
│   ├── rds/
│   ├── s3/
│   └── vpc/
├── src/
├── keys/
├── vars.tf
├── main.tf
├── outputs.tf
├── README.md
└── .gitignore

`modules` : répertoire pour y héberger nos différents modules.
`src` : répertoire pour y héberger les sources de notre application qui seront par la suite envoyées sur notre bucket S3.
`keys` : répertoire pour y héberger la paire de clé SSH, au cas où nous aurons besoin de nous connecter sur nos instances EC2.
`vars.tf` : fichier de variables du module racine.
`main.tf` : fichier de configuration principale du module racine.
`outputs.tf` : fichier de variables de sortie du module racine.
`README.md` : fichier de documentation principale de notre projet.
`.gitignore` : fichier contenant une liste de fichiers/dossiers à ignorer lors d'un commit.

! Good Luck

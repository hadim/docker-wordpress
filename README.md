# Docker Image for Wordpress

This instructions works for Centos 7 but any Linux system with Docker installed should work too.

## Features

- Multiple Wordpress instances.
- Automatic backup in 7z format.
- Automatic upload to Google Drive.
- Automatic HTTPS certificates with Let's Encrypt.
- Automatic restore most recent backups.

## Setup

Instructions for CentOS 7:

- Setup your environement with `CentOS_7_Docker_Setup.sh`.

```bash
wget https://raw.githubusercontent.com/hadim/docker-wordpress/master/scripts/CentOS_7_Docker_Setup.sh
bash "CentOS_7_Docker_Setup.sh"
```

- Clone the repo:

```bash
git clone https://github.com/hadim/docker-wordpress.git
```

- Copy the example folder to the parent of `docker-wordpress`:

```bash
cp -R docker-wordpress/containers/website1/ .

# Rename it to the domain name you want to use.
mv website1/ my-website.com/

# Set `PROJECT_PATH`.
cd my-website.com/
export PROJECT_PATH=$(pwd)
```

- Create directories:

```bash
mkdir -p "$PROJECT_PATH/../backups"
mkdir -p "$PROJECT_PATH/../pydrive"
```

- Install crontab rule:

```bash
(crontab -l 2>/dev/null; echo "30 6 * * * cd $PATH_TO_DOCKER_WORDPRESS && python36 scripts/Upload_Backup_To_Drive.py") | crontab -
```

- Put your `settings.yaml` and  `client_secret.json` files into `$PROJECT_PATH/../pydrive`.
- Create a JSON file called `websites.json` to map website names to its Google Drive ID:

```json
{
  "my-website.com": "1FuYWdjsiRfbFBz-WoQll8sddsOPAMdlld7f8p5VL"
}
```

## Usage

- Launch the proxy:

```bash
cd "$PROJECT_PATH/../docker-wordpress"
docker-compose pull
docker network create nginx-proxy
docker-compose up -d
docker-compose logs -f
# And check logs are ok.
```

- Launch one website:

```bash
cd "$PROJECT_PATH"
source ../docker-wordpress/containers/setup.sh my-website.com
docker-compose build
docker-compose up -d
docker-compose logs -f
# And check logs are ok.
```

- Manual backup:

```bash
cd "$PROJECT_PATH"
docker-compose exec wp-server /Backup.sh
```

- Get a Bash into the Wordpress server:

```bash
cd "$PROJECT_PATH"
docker-compose exec wp-server bash
```

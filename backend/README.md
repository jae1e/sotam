
# Kids info backend

A backend for kids info app.

## Development environment

### Requirements

* Docker
* MongoDB
* Python3
* Go 1.21

### Setup environment

```bash
# Setup python requirements
pip3 install -r scripts/requirements.txt

# Start MongoDB (Linux)
sudo systemctl start mongod
sudo systemctl status mongod
sudo systemctl enable mongod

# Start MongoDB (MacOS)
brew services start mongodb-community
```

### Data processing scripts

#### [build_hospital_database.py](./scripts/database/build_hospital_database.py)

It pulls hospital list from government APIs, and consolidates into a MongoDB database of full hospital information. It also builds DB info.

#### [edit_announcement.py](./scripts/database/edit_announcement.py)

A script to get, post, and delete announcement in the remote DB.

## Deploy

### Setup server environment

* Launch AWS EC2 instance with Ubuntu
* Install Docker
* Grant Docker permission

```bash
sudo groupadd docker
sudo gpasswd -a $USER docker
newgrp docker
sudo service docker restart
```

### Deploy scripts

Before start, set `SOTAM_BACKEND_IP` environment variable in ~/.zshrc.

#### [ec2_bash.sh](./scripts/deploy/ec2_bash.sh)

Log-in to EC2 and run bash.

#### [deploy_code.sh](./scripts/deploy/deploy_code.sh)

Copy the latest code to EC2 and build.

#### [relaunch_containers.sh](./scripts/deploy/restart_server.sh)

Restart the backend service in EC2.

#### [push_database.sh](./scripts/deploy/push_database.sh)

Dump the local database to a file, copy the file to EC2, backup current EC2 database, and load the database to mongo container in EC2.

#### [pull_database.sh](./scripts/deploy/pull_database.sh)

Dump the EC2 database to a file, copy the file to local, backup current local database, and load the database to local.

### Debugging in EC2

```bash
# start
docker compose up -d

# stop
docker compose down

# list docker containers
docker ps

# access to a container through bash
docker exec -it <container name> /bin/bash
```

## Etc

### Test scripts

#### [gov_api_test.py](./scripts/test/gov_api_test.py)

A test script for government hospital information API.

#### [api_test.py](./scripts/test/api_test.py)

A test script for backend API.

#### (Obsolete) [build_xlsx_list_from_file.py](./scripts/test/build_xlsx_list_from_file.py)

It reads `csv` hospital database files from government, and consolidates into a `xlsx` database of full hospital information.

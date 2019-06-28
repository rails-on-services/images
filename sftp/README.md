# SFTP Container with S3 Mount

## SFTP Mounts

The container uses s3fs to mount sftp users' home directory from S3 bucket and also some config files.

### SFTP user home directory

The whole /home directory is mounted from s3 prefix `home/`. If the s3 prefix object is not present in the bucket, the container will create it duirng initilization.

### SFTP config files

S3 prefix `config/` is mounted to the container at path `/opt/sftp`.

#### users.conf

The SFTP container periodically syncs users from a file `users.conf` at `/opt/sftp/` under the containers which maps to S3 object at `/sftp/config/users.conf`. The `users.conf` file is following same format as [atmoz/sftp](https://github.com/atmoz/sftp). The container will not having any SFTP user until the file is there.

#### SSH host keys

SSH host keys are also mounted from s3. The location is `/opt/sftp/sshx/ssh_host_*` inside the container which maps to s3 object keys `/sftp/config/sshx/ssh_host_*`. If the keys are not there, the container will create them during initialization.

#### Users' SSH authorized-keys

Users's SSH authorized-keys (SSH public key) are also mounted from S3. The location is `/opt/sftp/sshx/authorized-keys/{user_name}` inside the container which maps to s3 object keys `/sftp/config/sshx/authorized-keys/{user_name}`. Note that SSH server expects the SSH authorized keys are stored with proper file permissions (644 would be fine). 

The authorized-keys folder will be created by the container during initilization if it's not exisit. You can upload each user's public key to the container to allow them login using SSH key.

## Quickstart with Localstack

Localstack provides a local S3 service so you don't need an actual S3 bucket on AWS

### Start the service

```bash
docker-compose up
```

The SFTP service is now running on your localhost on port 2222.

### Create sftp users

The docker-compose-seed.yml is used to create the `users.conf` file inside the localstack s3 with your local [users.conf](./users.conf).

```bash
docker-compose -f docker-compose.yml -f docker-compose-seed.yml run --rm sftp
```

> The file users.conf contains three test users with passwords. The users are `foo`, `bar` and `baz`.
Their passwords are `pass`. All users have two directories they can write to: `uploads` and `downloads`

### Connect to the service

```bash
sftp -P 2222 foo@localhost
```

The password is `pass`

### Use the service

After logging in you can list files:

```bash
ls
```

Upload a file:

```bash
put README.md uploads
```

And logout:

```bash
exit
```

### Connect to the SFTP service with your SSH key

To connect with your ssh key as the user `foo` write your public key to the server's authorized-keys directory

```bash
# by default the sftp docker container id will be sftp_sftp_1
# first copy to the /tmp folder inside the container
docker cp ~/.ssh/id_rsa.pub sftp_sftp_1:/tmp/
# then copy into correct path inside the container
docker exec sftp_sftp_1 cp /tmp/id_rsa.pub /opt/sftp/sshx/authorized-keys/foo
# then make sure the file permission is correct
docker exec sftp_sftp_1 chmod 644 /opt/sftp/sshx/authorized-keys/foo
```

Now download the README.md that you uploaded previously:

```bash
sftp -P 2222 foo@localhost:uploads/README.md
```

## Quickstart with AWS

### Create AWS credentials for SFTP server to use

Replace the AWS credentials in docker-compose.yml with valid credentials and comment out the `BUCKET_ENDPOINT_URL` value

### Run the servcie

```bash
docker-compose down
docker-compose up
```

### Use the service

[Just as above](#Use the service)


## Notes

### Localstack

By default localstack will output TCP/IP communications between the SFTP container and localstack
To turn off the output, comment out the `DEBUG: S3` line in docker-compose.yml

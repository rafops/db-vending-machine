# DB Vending Machine

A Terraform plugin that creates a DB Vending Machine that creates copies of production DB instances into a development account.

## Configuration

Set the following Terraform variables to configure DB Vending Machine module:

- Set `backup_profile` to AWS credentials profile where DB Vending Machine will take backups from. Usually a production account.
- Set `restore_profile` to AWS credentials profile where DB Vending Machine will create DB instances from snapshots. Usually a development account.
- Set `source_db_instance` to DB instance identifier in the `backup_profile` account where snapshots will be taken from.

## Build Terraform

This Terraform module has a Dockerfile that creates a container with Terraform and its dependencies. To build the container, run the following command:

```
./build_terraform
```

## Build Lambda

This Terraform module Lambda functions depends on external dependencies. To download and vendorize these dependencies, run the following command:

```
./build_lambda
```

## Deploy

Deploy service infrastructure:

```
./deploy
```

## Test DB

To deploy a test db development/test purposes:

```
echo "create_test_db = true" > terraform.tfvars
./deploy
```

If you want to connect to the database, make sure to open default security group inbound rules to accept connections.

## Execute

To execute the state machine, create a new execution with the following input:

```json
{
    "db_instance_identifier": "db-vending-test"
}
```

## Teardown

To cleanup, run:

```
./teardown
```
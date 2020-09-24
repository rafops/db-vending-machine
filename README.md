# DB Vending Machine

A Terraform plugin that creates a DB Vending Machine that creates copies of production DB instances into a development account.

## Configuration

Set the following Terraform variables to configure DB Vending Machine module:

- Set `backup_profile` to AWS credentials profile where snapshots will be taken from. Usually a production account.
- Set `backup_db_instance` to DB instance identifier in the `backup_profile` account where snapshots will be taken from. Usually a production instance.
- Set `restore_profile` to AWS credentials profile where DB instances will be restored into. Usually a development account.
- Set `restore_vpc_id` to the VPC in the `restore_profile` account where DB instances will be restored into.
- Set `restore_subnet_ids` to a list containing a minimum of two subnets from the `restore_vpc_id`.

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

## Deploy test DB

To deploy a test db development/test purposes:

```
echo "create_test_db = true" > terraform.tfvars
./deploy
```

If you want to connect to the database, make sure to open default security group inbound rules to accept connections.

## Execute

To execute the state machine, run the following command:

```
./start_execution
```

## Test Lambdas

To test Lambda functions locally, run Lambci script passing the function name and the payload as follows:

```
./test_lambda create_snapshot '{"db_instance_identifier":"db-vending-test"}'
```

## Teardown

To cleanup, run:

```
./teardown
```

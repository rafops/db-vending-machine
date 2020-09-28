# DB Vending Machine

A Terraform plugin that creates a DB Vending Machine that creates copies of production DB instances into a development account.

## Configuration

Set the following Terraform variables to configure DB Vending Machine as a module or using `terraform.tfvars`:

- Set `source_profile` to AWS credentials profile where snapshots will be taken from. Usually a production account.
- Set `source_db_instance` to DB instance identifier in the `source_profile` account where snapshots will be taken from. Usually a production instance.
- Set `destination_profile` to AWS credentials profile where DB instances will be restored into. Usually a development account.
- Set `destination_vpc_id` to the VPC in the `destination_profile` account where DB instances will be restored into.
- Set `destination_subnet_ids` to a list containing a minimum of two subnets from the `destination_vpc_id`.

## Build Terraform

This Terraform module has a Dockerfile that creates a container with Terraform and its dependencies. To build the container, run the following command:

```
./build_terraform
```

## Build Lambda

To generate a lambda.zip package for deployment, run the following command:

```
./build_lambda
```

## Deploy

Deploy service infrastructure:

```
./deploy
```

## Deploy test DB

To deploy a test DB instance for development/test purposes:

```
./deploy_test
```

If you want to connect to the database, make sure to open default security group inbound rules to accept connections.

## Restore

To restore a DB instance, run the following command:

```
./restore
```

If you restored a test DB instance, run the following command to connect to it:

```
./psql_restore <host of restored DB instance> db_vending test
```

## Test Lambdas

To test Lambda functions locally, run Lambci script passing the function name and the payload as follows:

```
./test_lambda create_snapshot '{"db_instance_identifier":"db-vending-test"}'
```

## Teardown

To teardown infrastructure, run:

```
./teardown
```

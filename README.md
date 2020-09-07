# DB Vending Machine

A Terraform plugin that creates a DB Vending Machine from production snapshots of RDS instances.

## Build Terraform

Build Terraform container containing Terraform and its dependencies:

```
./build_terraform
```

## Build Lambda

Download and vendorize Lambda dependencies:

```
./build_lambda
```

## Deploy

Deploy service infrastructure:

```
./deploy
```

## Execute

To execute the state machine, create a new execution with the following input:

```json
{
    "db_instance_identifier": "my-instance"
}
```
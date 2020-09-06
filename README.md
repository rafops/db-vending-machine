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

## Deploy infrastructure

Deploy service infrastructure for a specific source DB instance identifier:

```
./deploy db-instance
```

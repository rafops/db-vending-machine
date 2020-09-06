# DB Vending Machine

A Terraform plugin that creates an RDS vending machine from production snapshots.

Build Terraform container:

```
./build_terraform
```

Build Lambda:

```
./build_lambda
```

Apply Terraform:

```
./terraform apply -var source_db_instance_identifier=db-instance
```

require 'logger'
require 'json'
require 'securerandom'
require 'aws-sdk-rds'


$client = Aws::RDS::Client.new

def handler(event:, context:)
  unless event.has_key? "db_snapshot_identifier"
    raise "Input key db_snapshot_identifier not specified"
  end

  logger = Logger.new($stdout)
  db_snapshot_identifier = event["db_snapshot_identifier"]
  
  logger.info("Creating instance #{db_instance_identifier} from snapshot #{db_snapshot_identifier}")

  # Snapshot
  response = $client.describe_db_snapshots({
    db_snapshot_identifier: db_snapshot_identifier
  })
  db_snapshot = response.to_h[:db_snapshots].first

  # Source instance
  response = $client.describe_db_instances({
    db_instance_identifier: db_snapshot[:db_instance_identifier]
  })
  source_db_instance = response.to_h[:db_instances].first

  master_user_password = SecureRandom.alphanumeric(16)

  response = client.create_db_instance({
    db_instance_identifier: db_snapshot_identifier,
    allocated_storage: db_snapshot[:allocated_storage],
    db_instance_class: source_db_instance[:db_instance_class],
    engine: db_snapshot[:engine],
    master_username: db_snapshot[:master_username],
    master_user_password: master_user_password,
    vpc_security_group_ids: ["String"], # TODO create with Terraform / pass as variables?
    availability_zone: "String", # TODO ...
    db_subnet_group_name: "String", # TODO ...
    db_parameter_group_name: source_db_instance[:db_parameter_groups][:db_parameter_group_name],
    backup_retention_period: 0,
    port: db_snapshot[:port],
    multi_az: false,
    engine_version: db_snapshot[:engine_version],
    auto_minor_version_upgrade: false,
    license_model: db_snapshot[:license_model],
    option_group_name: db_snapshot[:option_group_name],
    publicly_accessible: source_db_instance[:publicly_accessible],
    tags: [
      {
        key: "service",
        value: "db-vending-machine",
      },
    ],
    storage_type: db_snapshot[:storage_type],
    storage_encrypted: db_snapshot[:encrypted],
    # kms_key_id: "String", # TODO
    copy_tags_to_snapshot: source_db_instance[:copy_tags_to_snapshot],
    enable_iam_database_authentication: true,
    enable_performance_insights: false,
    processor_features: db_snapshot[:processor_features],
    deletion_protection: false,
  })

  db_instance = response.to_h[:db_instance]
  unless db_instance.is_a? Hash and db_instance.has_key? :db_instance_identifier
    logger.debug("Response: #{response.inspect}")
    raise "Invalid response when calling #create_db_instance, key :db_instance_identifier not found"
  end

  {
    "db_instance_identifier": db_snapshot[:db_instance_identifier],
    "master_user_password": master_user_password
  }
end
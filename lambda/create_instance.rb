require 'logger'
require 'json'
require 'aws-sdk-rds'
require 'pp'


def handler(event:, context:)
  [
    "db_instance_identifier",
    "db_snapshot_identifier"
  ].each do |k|
    unless event.has_key? k
      raise "Event key #{k} not specified"
    end
  end

  db_instance_identifier = event["db_instance_identifier"]
  db_snapshot_identifier = event["db_snapshot_identifier"]
  service_namespace = ENV["service_namespace"]
  security_group_id = ENV["security_group_id"]
  restore_role_arn = ENV["restore_role_arn"]
  restore_db_instance_identifier = db_snapshot_identifier.sub(/-copied$/, "")

  logger = Logger.new($stdout)
  client = Aws::RDS::Client.new

  response = client.describe_db_instances({
    db_instance_identifier: db_instance_identifier
  })

  db_instance = response.to_h[:db_instances].to_a.first
  unless db_instance.is_a? Hash
    logger.debug("Response: #{response.inspect}")
    raise "Invalid response when calling #describe_db_instances, instance #{db_instance_identifier} not found"
  end

  role_credentials = Aws::AssumeRoleCredentials.new(
    client: Aws::STS::Client.new,
    role_arn: restore_role_arn,
    role_session_name: "CreateInstanceSession"
  )
  client = Aws::RDS::Client.new({
    credentials: role_credentials
  })

  db_snapshot = Aws::RDS::DBSnapshot.new({
    instance_id: db_instance_identifier,
    snapshot_id: db_snapshot_identifier,
    client: client
  })

  logger.info("Restoring DB instance #{restore_db_instance_identifier} from snapshot")

  restore_db_instance = db_snapshot.restore({
    db_instance_identifier: restore_db_instance_identifier,
    db_instance_class: db_instance[:db_instance_class],
    # port: 1,
    # availability_zone: "String",
    ## only lowercase alphanumeric characters, hyphens, underscores, periods, and spaces allowed
    db_subnet_group_name: "DBVending-#{service_namespace}-Restore".downcase,
    multi_az: false,
    publicly_accessible: db_instance[:publicly_accessible],
    auto_minor_version_upgrade: false,
    license_model: db_instance[:license_model],
    ## DBName must be null when Restoring for this Engine (PostgreSQL)
    # db_name: db_instance[:db_name],
    engine: db_instance[:engine],
    # iops: 1,
    # option_group_name: "String",
    tags: [
      {
        key: "service",
        value: "DBVending-#{service_namespace}"
      }
    ],
    storage_type: db_instance[:storage_type],
    # tde_credential_arn: "String",
    # tde_credential_password: "String",
    vpc_security_group_ids: [security_group_id],
    # domain: "String",
    copy_tags_to_snapshot: false,
    # domain_iam_role_name: "String",
    enable_iam_database_authentication: true,
    # enable_cloudwatch_logs_exports: ["String"],
    # processor_features: [
    #   {
    #     name: "String",
    #     value: "String",
    #   },
    # ],
    # use_default_processor_features: false,
    # db_parameter_group_name: "String",
    deletion_protection: false
  })

  {
    "db_instance_identifier": restore_db_instance_identifier
  }
end
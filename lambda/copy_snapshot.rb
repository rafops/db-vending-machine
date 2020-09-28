require 'logger'
require 'json'
require 'aws-sdk-rds'


def handler(event:, context:)
  unless event.has_key? "db_snapshot_identifier"
    raise "Event key db_snapshot_identifier not specified"
  end

  db_snapshot_identifier = event["db_snapshot_identifier"]
  service_namespace = ENV["service_namespace"]
  aws_region = ENV["AWS_REGION"]
  source_account_id = ENV["source_account_id"]
  kms_key_id = ENV["kms_key_id"]
  vending_role_arn = ENV["vending_role_arn"]

  logger = Logger.new($stdout)
  client = Aws::STS::Client.new

  source_db_snapshot_identifier = [
    "arn:aws:rds",
    aws_region,
    source_account_id,
    "snapshot",
    db_snapshot_identifier
  ].join(":")
  target_db_snapshot_identifier = db_snapshot_identifier.sub(/rekeyed$/, "copied")
  
  role_credentials = Aws::AssumeRoleCredentials.new(
    client: Aws::STS::Client.new,
    role_arn: vending_role_arn,
    role_session_name: "CopySnapshotSession"
  )
  client = Aws::RDS::Client.new({
    credentials: role_credentials
  })

  logger.info("Copying snapshot #{source_db_snapshot_identifier}")

  response = client.copy_db_snapshot({
    source_db_snapshot_identifier: source_db_snapshot_identifier,
    target_db_snapshot_identifier: target_db_snapshot_identifier,
    kms_key_id: kms_key_id,
    tags: [
      {
        key: "service",
        value: "DBVending-#{service_namespace}"
      }
    ]
  })

  db_snapshot = response.to_h[:db_snapshot]
  unless db_snapshot.is_a? Hash and db_snapshot.has_key? :db_snapshot_identifier
    logger.debug("Response: #{response.inspect}")
    raise "Invalid response when calling #copy_db_snapshot, key :db_snapshot_identifier not found"
  end

  {
    "db_snapshot_identifier": db_snapshot[:db_snapshot_identifier]
  }
end
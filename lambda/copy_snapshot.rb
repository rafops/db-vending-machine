require 'logger'
require 'json'
require 'aws-sdk-rds'


def handler(event:, context:)
  [
    "db_snapshot_identifier",
    "db_snapshot_account_id",
    "db_snapshot_region",
    "restore_role_arn",
    "kms_key_id"
  ].each do |k|
    unless event.has_key? k
      raise "Event key #{k} not specified"
    end  
  end

  logger = Logger.new($stdout)
  client = Aws::STS::Client.new

  source_db_snapshot_identifier = [
    "arn:aws:rds",
    event["db_snapshot_region"],
    event["db_snapshot_account_id"],
    "snapshot",
    event["db_snapshot_identifier"]
  ].join(":")
  target_db_snapshot_identifier = event["db_snapshot_identifier"].sub(/rekeyed$/, "copied")
  kms_key_id = event["kms_key_id"]
  service_namespace = event.has_key?("service_namespace") ? event["service_namespace"] : "Default"
  
  role_credentials = Aws::AssumeRoleCredentials.new(
    client: Aws::STS::Client.new,
    role_arn: event["restore_role_arn"],
    role_session_name: "CopySnapshotSession"
  )
  client = Aws::RDS::Client.new({
    credentials: role_credentials
  })

  db_snapshot = nil

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
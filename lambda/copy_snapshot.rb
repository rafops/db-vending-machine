require 'logger'
require 'json'
require 'aws-sdk-rds'


def handler(event:, context:)
  [
    "db_snapshot_identifier",
    "db_snapshot_account_id",
    "db_snapshot_region",
    "restore_role_arn"
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
  unique_id = event["execution_id"].to_s.split(":").last.to_s.split("-").first
  
  response = client.assume_role({
    role_arn: event["restore_role_arn"],
    role_session_name: "CopySnapshot_#{unique_id}", 
  })
  client = Aws::RDS::Client.new(
    credentials: response[:credentials]
  )

  db_snapshot = nil

  logger.info("Copying snapshot #{source_db_snapshot_identifier}")

  response = client.copy_db_snapshot({
    source_db_snapshot_identifier: source_db_snapshot_identifier,
    target_db_snapshot_identifier: target_db_snapshot_identifier,
    copy_tags: true
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
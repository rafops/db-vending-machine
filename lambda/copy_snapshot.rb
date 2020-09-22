require 'logger'
require 'json'
require 'aws-sdk-rds'


$client = Aws::RDS::Client.new

def handler(event:, context:)
  unless event.has_key? "db_snapshot_identifier"
    raise "Event key db_snapshot_identifier not specified"
  end

  unless event.has_key? "db_snapshot_account_id"
    raise "Event key db_snapshot_account_id not specified"
  end

  unless event.has_key? "db_snapshot_region"
    raise "Event key db_snapshot_region not specified"
  end

  logger = Logger.new($stdout)

  source_db_snapshot_identifier = [
    "arn:aws:rds",
    event["db_snapshot_region"],
    event["db_snapshot_account_id"],
    "snapshot",
    event["db_snapshot_identifier"]
  ].join(":")
  target_db_snapshot_identifier = event["db_snapshot_identifier"].sub(/rekeyed$/, "copied")
  db_snapshot = nil

  logger.info("Copying snapshot #{source_db_snapshot_identifier}")

  response = $client.copy_db_snapshot({
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
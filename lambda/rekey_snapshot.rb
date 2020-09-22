require 'logger'
require 'json'
require 'aws-sdk-rds'


def handler(event:, context:)
  [
    "db_snapshot_identifier",
    "kms_key_id"
  ].each do |k|
    unless event.has_key? k
      raise "Event key #{k} not specified"
    end  
  end

  logger = Logger.new($stdout)
  client = Aws::RDS::Client.new

  source_db_snapshot_identifier = event["db_snapshot_identifier"]
  kms_key_id = event["kms_key_id"]
  target_db_snapshot_identifier = "#{source_db_snapshot_identifier}-rekeyed"
  db_snapshot = nil

  logger.info("Re-keying snapshot #{source_db_snapshot_identifier}")

  response = client.copy_db_snapshot({
    source_db_snapshot_identifier: source_db_snapshot_identifier,
    target_db_snapshot_identifier: target_db_snapshot_identifier,
    kms_key_id: kms_key_id,
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
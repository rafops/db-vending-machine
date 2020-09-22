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

  service_namespace = event.has_key?("service_namespace") ? event["service_namespace"] : "Default"
  source_db_snapshot_identifier = event["db_snapshot_identifier"]
  kms_key_id = event["kms_key_id"]

  source_id_split = source_db_snapshot_identifier.split('-')
  source_id_split.pop
  source_id_split.push(SecureRandom.uuid.split("-").first)
  target_db_snapshot_identifier = "#{source_id_split.join('-')}"
  db_snapshot = nil

  logger.info("Re-keying snapshot #{source_db_snapshot_identifier} into #{target_db_snapshot_identifier}")

  response = $client.copy_db_snapshot({
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
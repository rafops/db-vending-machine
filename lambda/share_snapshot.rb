require 'logger'
require 'json'
require 'aws-sdk-rds'


def handler(event:, context:)
  unless event.has_key? "db_snapshot_identifier"
    raise "Event key db_snapshot_identifier not specified"
  end

  db_snapshot_identifier = event["db_snapshot_identifier"]
  destination_account_id = ENV["destination_account_id"]

  logger = Logger.new($stdout)
  client = Aws::RDS::Client.new

  logger.info("Sharing snapshot #{db_snapshot_identifier}")

  response = client.modify_db_snapshot_attribute({
    attribute_name: "restore", 
    db_snapshot_identifier: db_snapshot_identifier,
    values_to_add: [
      destination_account_id
    ], 
  })

  db_snapshot = response.to_h[:db_snapshot_attributes_result]
  unless db_snapshot.is_a? Hash and db_snapshot.has_key? :db_snapshot_identifier
    logger.debug("Response: #{response.inspect}")
    raise "Invalid response when calling #modify_db_snapshot_attribute, key :db_snapshot_identifier not found"
  end

  {
    "db_snapshot_identifier": db_snapshot[:db_snapshot_identifier]
  }
end
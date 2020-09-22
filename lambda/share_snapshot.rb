require 'logger'
require 'json'
require 'aws-sdk-rds'


$client = Aws::RDS::Client.new

def handler(event:, context:)
  unless event.has_key? "db_snapshot_identifier"
    raise "Event key db_snapshot_identifier not specified"
  end

  unless event.has_key? "restore_account_id"
    raise "Event key restore_account_id not specified"
  end

  db_snapshot_identifier = event["db_snapshot_identifier"]
  restore_account_id = event["restore_account_id"]

  logger = Logger.new($stdout)
  logger.info("Sharing snapshot #{db_snapshot_identifier}")

  response = $client.modify_db_snapshot_attribute({
    attribute_name: "restore", 
    db_snapshot_identifier: db_snapshot_identifier,
    values_to_add: [
      restore_account_id
    ], 
  })

  result = response.to_h[:db_snapshot_attributes_result]
  unless result.is_a? Hash and result.has_key? :db_snapshot_identifier
    logger.debug("Response: #{response.inspect}")
    raise "Invalid response when calling #modify_db_snapshot_attribute, key :db_snapshot_identifier not found"
  end

  result
end
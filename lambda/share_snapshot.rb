require 'logger'
require 'json'
require 'aws-sdk-rds'


$client = Aws::RDS::Client.new

def handler(event:, context:)
  unless event.has_key? "db_snapshot_identifier"
    raise "Input key db_snapshot_identifier not specified"
  end

  logger = Logger.new($stdout)
  db_snapshot_identifier = event["db_snapshot_identifier"]

  logger.info("Sharing snapshot #{db_snapshot_identifier}")

  response = $client.modify_db_snapshot_attribute({
    attribute_name: "restore", 
    db_snapshot_identifier: db_snapshot_identifier,
    # TODO: parameterize
    values_to_add: [
      "501253995157"
    ], 
  })

  result = response.to_h[:db_snapshot_attributes_result]
  unless result.is_a? Hash and result.has_key? :db_snapshot_identifier
    logger.debug("Response: #{response.inspect}")
    raise "Invalid response when calling #modify_db_snapshot_attribute, key :db_snapshot_identifier not found"
  end

  result
end
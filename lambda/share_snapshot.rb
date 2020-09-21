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
  db_snapshot = nil

  logger.info("Sharing snapshot #{db_snapshot_identifier}")

  response = $client.modify_db_snapshot_attribute({
    attribute_name: "restore", 
    db_snapshot_identifier: db_snapshot_identifier,
    # TODO: parameterize
    values_to_add: [
      "501253995157"
    ], 
  })

  response.to_h
end
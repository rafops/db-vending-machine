require 'logger'
require 'json'
require 'aws-sdk-rds'


$client = Aws::RDS::Client.new

def handler(event:, context:)
  logger = Logger.new($stdout)
  db_snapshot_identifier = "#{ENV['SOURCE_DB_INSTANCE_IDENTIFIER']}-#{Time.now.to_i}"

  logger.info("creating snapshot #{db_snapshot_identifier} from source db instance #{ENV['SOURCE_DB_INSTANCE_IDENTIFIER']}")

  response = $client.create_db_snapshot({
    db_instance_identifier: ENV['SOURCE_DB_INSTANCE_IDENTIFIER'],
    db_snapshot_identifier: db_snapshot_identifier,
    tags: [
      {
        key: "service",
        value: "db-vending-machine",
      },
    ]
  })

  response.to_h
end
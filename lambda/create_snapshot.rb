require 'logger'
require 'json'
require 'securerandom'
require 'aws-sdk-rds'


$client = Aws::RDS::Client.new

def handler(event:, context:)
  unless event.has_key? "db_instance_identifier"
    raise "Input key db_instance_identifier not specified"
  end

  logger = Logger.new($stdout)
  db_instance_identifier = event["db_instance_identifier"]
  # Can't be null, empty, or blank
  # Must contain from 1 to 255 letters, numbers, or hyphens
  # First character must be a letter
  # Can't end with a hyphen or contain two consecutive hyphens
  db_snapshot_identifier = "db-vending-machine-#{Time.now.to_i}-#{SecureRandom.uuid.split("-").first}"
  
  logger.info("Creating snapshot #{db_snapshot_identifier} from db instance #{db_instance_identifier}")

  response = $client.create_db_snapshot({
    db_instance_identifier: db_instance_identifier,
    db_snapshot_identifier: db_snapshot_identifier,
    tags: [
      {
        key: "service",
        value: "db-vending-machine",
      },
    ]
  })

  db_snapshot = response.to_h[:db_snapshot]
  unless db_snapshot.is_a? Hash and db_snapshot.has_key? :db_snapshot_identifier
    logger.debug("Response: #{response.inspect}")
    raise "Invalid response when calling #create_db_snapshot, key :db_snapshot_identifier not found"
  end

  {
    "db_snapshot_identifier": db_snapshot[:db_snapshot_identifier]
  }
end
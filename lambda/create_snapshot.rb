require 'logger'
require 'json'
require 'aws-sdk-rds'


$client = Aws::RDS::Client.new

def handler(event:, context:)
  unless event.has_key? "db_instance_identifier"
    raise "Event key db_instance_identifier not specified"
  end

  logger = Logger.new($stdout)

  service_namespace = event.has_key?("service_namespace") ? event["service_namespace"] : "Default"
  db_instance_identifier = event["db_instance_identifier"]
  # Generate a unique ID based on the first token of execution id UUID
  # Format: arn:aws:states:region:account_id:execution:state_machine_name:UUID
  unique_id = event["execution_id"].to_s.split(":").last.to_s.split("-").first

  # Can't be null, empty, or blank
  # Must contain from 1 to 255 letters, numbers, or hyphens
  # First character must be a letter
  # Can't end with a hyphen or contain two consecutive hyphens
  # This value is stored as a lowercase string
  db_snapshot_identifier = [
    "DBVending",
    service_namespace,
    Time.now.to_i,
    unique_id
  ].compact.join("-").downcase
  
  logger.info("Creating snapshot #{db_snapshot_identifier} from instance #{db_instance_identifier}")

  response = $client.create_db_snapshot({
    db_instance_identifier: db_instance_identifier,
    db_snapshot_identifier: db_snapshot_identifier,
    tags: [
      {
        key: "service",
        value: "DBVending-#{service_namespace}", # TODO: set based on service_namespace
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
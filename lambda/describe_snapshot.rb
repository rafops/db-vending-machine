require 'logger'
require 'json'
require 'aws-sdk-rds'


$client = Aws::RDS::Client.new

def handler(event:, context:)
  raise "Invalid input, expecting a Hash" unless event.is_a? Hash
  raise "Input key db_snapshot_identifier not specified" unless event.has_key? "db_snapshot_identifier"

  logger = Logger.new($stdout)
  db_snapshot_identifier = event["db_snapshot_identifier"]
  db_snapshot = nil

  loop do
    logger.info("Describing snapshot #{db_snapshot_identifier}")

    response = $client.describe_db_snapshots({
      db_snapshot_identifier: db_snapshot_identifier
    })

    db_snapshot = response.to_h[:db_snapshots].first
    unless db_snapshot.is_a? Hash and db_snapshot.has_key? :status
      logger.debug("Response: #{response.inspect}")
      raise "Invalid response when calling #describe_db_snapshots, key :status not found"
    end
  
    break if db_snapshot[:status] == "available"
    logger.info("Snapshot is not available yet, sleeping 30 seconds")
    sleep(30)
  end

  {
    "db_snapshot_identifier": db_snapshot[:db_snapshot_identifier],
    "status":                 db_snapshot[:status]
  }
end
require 'logger'
require 'json'
require 'aws-sdk-rds'


def handler(event:, context:)
  unless event.has_key? "db_snapshot_identifier"
    raise "Event key db_snapshot_identifier not specified"
  end

  logger = Logger.new($stdout)
  client = Aws::RDS::Client.new

  db_snapshot_identifier = event["db_snapshot_identifier"]
  db_snapshot = nil

  logger.info("Checking snapshot #{db_snapshot_identifier}")

  response = client.describe_db_snapshots({
    db_snapshot_identifier: db_snapshot_identifier
  })

  db_snapshot = response.to_h[:db_snapshots].first
  unless db_snapshot.is_a? Hash and db_snapshot.has_key? :status
    logger.debug("Response: #{response.inspect}")
    raise "Invalid response when calling #describe_db_snapshots, key :status not found"
  end

  {
    "db_snapshot_identifier": db_snapshot[:db_snapshot_identifier],
    "status":                 db_snapshot[:status]
  }
end
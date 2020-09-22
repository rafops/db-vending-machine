require 'logger'
require 'json'
require 'aws-sdk-rds'


def handler(event:, context:)
  [
    "db_snapshot_identifier",
    "restore_role_arn"
  ].each do |k|
    unless event.has_key? k
      raise "Event key #{k} not specified"
    end  
  end

  logger = Logger.new($stdout)
  role_credentials = Aws::AssumeRoleCredentials.new(
    client: Aws::STS::Client.new,
    role_arn: event["restore_role_arn"],
    role_session_name: "CheckSnapshotCopySession"
  )
  client = Aws::RDS::Client.new({
    credentials: role_credentials
  })

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
require 'logger'
require 'json'
require 'aws-sdk-rds'


def handler(event:, context:)
  [
    "db_instance_identifier",
    "restore_role_arn"
  ].each do |k|
    unless event.has_key? k
      raise "Event key #{k} not specified"
    end  
  end

  db_instance_identifier = event["db_instance_identifier"]

  logger = Logger.new($stdout)
  role_credentials = Aws::AssumeRoleCredentials.new(
    client: Aws::STS::Client.new,
    role_arn: event["restore_role_arn"],
    role_session_name: "CheckInstanceStatusSession"
  )
  client = Aws::RDS::Client.new({
    credentials: role_credentials
  })
  
  logger.info("Checking DB instance #{db_instance_identifier}")

  response = client.describe_db_instances({
    db_instance_identifier: db_instance_identifier
  })

  db_instance = response.to_h[:db_instances].first
  unless db_instance.is_a? Hash and db_instance.has_key? :db_instance_status
    logger.debug("Response: #{response.inspect}")
    raise "Invalid response when calling #describe_db_instances, key :status not found"
  end

  {
    "db_instance_identifier": db_instance[:db_instance_identifier],
    "status":                 db_instance[:db_instance_status]
  }
end
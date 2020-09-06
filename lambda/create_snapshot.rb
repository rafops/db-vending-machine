require 'logger'
require 'json'
require 'aws-sdk-rds'


$client = Aws::RDS::Client.new(
  region: ENV['AWS_REGION'],
  credentials: Aws::AssumeRoleCredentials.new(
    client: Aws::STS::Client.new,
    role_arn: ENV['LAMBDA_ROLE_ARN'],
    role_session_name: "lambda-role-session"
  )
)

def lambda_handler(event:, context:)
  logger = Logger.new($stdout)

  logger.info('## ENVIRONMENT VARIABLES')
  vars = Hash.new
  ENV.each do |variable|
    vars[variable[0]] = variable[1]
  end
  logger.info(vars.to_json)

  logger.info('## EVENT')
  logger.info(event.to_json)
  logger.info('## CONTEXT')
  logger.info(context)

  response = $client.create_db_snapshot({
    db_instance_identifier: ENV['SOURCE_DB_INSTANCE_IDENTIFIER'], 
    db_snapshot_identifier: "#{ENV['SOURCE_DB_INSTANCE_IDENTIFIER']}-snapshot", 
  })

  response.to_h
end
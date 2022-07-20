terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.21.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

terraform {
  backend "s3" {
    bucket  = "apfie-configurations"
    key     = "terraform/demos/lambda-modules.tfstate"
    region  = "eu-central-1"
    profile = "default"
  }
}


# craete bucket
# add bucket to lambda

module "lambda_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "lambda-from-modules"
  description   = "Lambda function created with a module"
  handler       = "index.handler"
  runtime       = "nodejs16.x"
  source_path   = "./lambda"
  publish       = true
  timeout       = 10

  store_on_s3 = true
  s3_bucket   = "apfie-people"

  allowed_triggers = {
    AllowExecutionFromAPIGateway = {
      service    = "apigateway"
      source_arn = "${module.api_gateway.apigatewayv2_api_execution_arn}/*/*"
    }
  }
}

module "other_lambda" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "lambda-from-modules-2"
  description   = "Lambda function created with a module (another one)"
  handler       = "index.handler"
  runtime       = "nodejs16.x"
  source_path   = "./other-lambda"
  publish       = true
  timeout       = 10

  store_on_s3 = true
  s3_bucket   = "apfie-people"

  allowed_triggers = {
    AllowExecutionFromAPIGateway = {
      service    = "apigateway"
      source_arn = "${module.api_gateway.apigatewayv2_api_execution_arn}/*/*"
    }
  }
}

module "api_gateway" {
  source = "terraform-aws-modules/apigateway-v2/aws"

  name          = "http-api-from-modules"
  description   = "HTTP API from terraform modules"
  protocol_type = "HTTP"

  create_api_domain_name = false

  cors_configuration = {
    allow_headers = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token", "x-amz-user-agent"]
    allow_methods = ["*"]
    allow_origins = ["*"]
  }

  integrations = {
    "GET /" = {
      lambda_arn = module.lambda_function.lambda_function_arn
    }
    "GET /other" = {
      lambda_arn = module.other_lambda.lambda_function_arn
    }
  }
}

output "api_endpoint" {
  description = "The URI of the API"
  value       = module.api_gateway.apigatewayv2_api_api_endpoint
}

variable "aws_region" {
  description = "Please Specify The Region"
}

variable "access_key" {
  description = "Please Provide Access Key"
}

variable "secret_key" {
  description = "Please Provide Secret Key"
}

variable "aws_account_id" {
  description = "Please Provide your account id"
}

variable "bucket_prefix" {
  default = "s3acl"
}

variable "sns_topic_arn" {
  default = "arn:aws:sns:us-east-1:855172423373:sns_config"
}

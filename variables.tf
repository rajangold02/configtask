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
  default = "arn:aws:sns:us-west-2:961508331227:sns_config"
}

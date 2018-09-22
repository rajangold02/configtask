provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.aws_region}"
}

#Setting up role for configuration Record

resource "aws_iam_role" "config" {
  name = "config-example"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "policy" {
  name        = "test-policy"
  description = "A test policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
				"sns:*",
                "config:Get*",
                "config:List*",
                "config:Put*",
                "s3:*",
                "cloudwatch:DescribeAlarms",
                "config:Describe*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "config" {
  role       = "${aws_iam_role.config.name}"
  policy_arn = "${aws_iam_policy.policy.arn}"
}

# Configuration Record To Write In Bucket

resource "aws_s3_bucket" "config" {
  bucket_prefix = "${var.bucket_prefix}"
  acl           = "private"
  region        = "${var.aws_region}"

  tags = "${map("Name", "Config Bucket")}"
}

resource "aws_s3_bucket_policy" "config_bucket_policy" {
  bucket = "${aws_s3_bucket.config.id}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Allow bucket ACL check",
      "Effect": "Allow",
      "Principal": {
        "Service": [
         "config.amazonaws.com"
        ]
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "${aws_s3_bucket.config.arn}",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "true"
        }
      }
    },
    {
      "Sid": "Allow bucket write",
      "Effect": "Allow",
      "Principal": {
        "Service": [
         "config.amazonaws.com"
        ]
      },
      "Action": "s3:PutObject",
      "Resource": "${aws_s3_bucket.config.arn}/${var.bucket_prefix}/AWSLogs/${var.aws_account_id}/Config/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        },
        "Bool": {
          "aws:SecureTransport": "true"
        }
      }
    },
    {
      "Sid": "Require SSL",
      "Effect": "Deny",
      "Principal": {
        "AWS": "*"
      },
      "Action": "s3:*",
      "Resource": "${aws_s3_bucket.config.arn}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY
}

# set up the  Config Recorder

resource "aws_config_configuration_recorder" "config" {
  name     = "config-example"
  role_arn = "${aws_iam_role.config.arn}"

  recording_group {
    all_supported                 = false
    include_global_resource_types = false
    resource_types                = ["AWS::S3::Bucket"]
  }
}

resource "aws_config_delivery_channel" "config" {
  name           = "config-example"
  s3_bucket_name = "${aws_s3_bucket.config.bucket}"
  s3_key_prefix  = "${var.bucket_prefix}"
  sns_topic_arn  = "${aws_sns_topic.sns.arn}"

  snapshot_delivery_properties {
    delivery_frequency = "Three_Hours"
  }

  depends_on = ["aws_config_configuration_recorder.config"]
}

resource "aws_config_configuration_recorder_status" "config" {
  name       = "${aws_config_configuration_recorder.config.name}"
  is_enabled = true
  depends_on = ["aws_config_delivery_channel.config"]
}

# set up the Config Recorder rules

resource "aws_config_config_rule" "s3_bucket_public_write_prohibited" {
  name = "s3_bucket_public_write_prohibited"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_WRITE_PROHIBITED"
  }

  depends_on = ["aws_config_configuration_recorder.config"]
}

resource "aws_config_config_rule" "s3_bucket_public_read_prohibited" {
  name = "s3_bucket_public_read_prohibited"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }

  depends_on = ["aws_config_configuration_recorder.config"]
}

resource "aws_sns_topic" "sns" {
  name = "aws_config"

  provisioner "local-exec" {
    command = "aws sns subscribe --topic-arn ${aws_sns_topic.sns.arn} --protocol email --notification-endpoint ${var.email}"
  }
}

# frozen_string_literal: true

# Fix for Ruby 3.4+ with aws-sdk-s3 and S3-compatible storage (Cloudflare R2)
# The AWS SDK defaults to sending multiple checksums which S3-compatible services reject.
# See: https://github.com/aws/aws-sdk-ruby/issues/3126

require "aws-sdk-s3"

Aws.config.update(
  request_checksum_calculation: "when_required",
  response_checksum_validation: "when_required"
)

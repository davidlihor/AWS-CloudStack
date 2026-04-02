resource "aws_kms_key" "cloudfront_signer" {
  description              = "KMS Key for CloudFront Signing"
  customer_master_key_spec = "RSA_2048"
  key_usage                = "SIGN_VERIFY"
}

data "aws_kms_public_key" "pub" {
  key_id = aws_kms_key.cloudfront_signer.id
}


data "aws_kms_public_key" "pub" {
  key_id = var.kms_key_cloudfront_signer_id
}

import {
  to = aws_iam_user.backend
  id = var.iam_user_name
}

resource "aws_iam_user" "backend" {
  name = var.iam_user_name

  lifecycle {
    prevent_destroy = true
  }
}

data "aws_iam_policy_document" "backend" {
  statement {
    sid    = "S3Access"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]
    resources = [
      aws_s3_bucket.receipts.arn,
      "${aws_s3_bucket.receipts.arn}/*",
    ]
  }

  statement {
    sid    = "TextractAccess"
    effect = "Allow"
    actions = [
      "textract:DetectDocumentText",
      "textract:AnalyzeDocument",
      "textract:StartDocumentTextDetection",
      "textract:GetDocumentTextDetection",
    ]
    resources = ["*"]
  }

  statement {
    sid     = "BedrockAccess"
    effect  = "Allow"
    actions = ["bedrock:InvokeModel"]
    # Wildcard on region and account to cover cross-region inference profiles
    # (model ID prefix "us." routes through us-east-1/us-west-2 automatically).
    resources = [
      "arn:aws:bedrock:*::foundation-model/*",
      "arn:aws:bedrock:*:*:inference-profile/*",
    ]
  }
}

resource "aws_iam_policy" "backend" {
  name        = "reclaima-backend-policy"
  description = "S3, Textract, and Bedrock permissions for the Reclaima backend"
  policy      = data.aws_iam_policy_document.backend.json
}

resource "aws_iam_user_policy_attachment" "backend" {
  user       = aws_iam_user.backend.name
  policy_arn = aws_iam_policy.backend.arn
}

# Terraform owns this access key's lifecycle. To rotate credentials:
# run `terraform apply -replace=aws_iam_access_key.backend` — Terraform
# destroys the old key, creates a new one, and writes it to Infisical in one apply.
#
# IMPORTANT: If the IAM user already has an existing access key that was
# created manually, you have two options before running `terraform apply`:
#   1. Delete the old key in the AWS Console (recommended — keeps you under
#      the 2-key-per-user limit and avoids credential confusion).
#   2. Import it: `terraform import aws_iam_access_key.backend <key-id>`
#      (the secret can't be recovered, so Infisical won't be updated for
#      the imported key — option 1 is cleaner).
resource "aws_iam_access_key" "backend" {
  user = aws_iam_user.backend.name
}

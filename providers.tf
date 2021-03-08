provider "aws" {
  region = var.aws_default_region
  /*
    Set Credentials via environment variables
    $ export AWS_ACCESS_KEY_ID="anaccesskey"
    $ export AWS_SECRET_ACCESS_KEY="asecretkey"
  */
}
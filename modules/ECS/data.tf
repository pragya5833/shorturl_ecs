data "aws_secretsmanager_secret" "db-username" {
  name = var.dbcreds_name
}
data "aws_secretsmanager_secret_version" "db-username-secret-version" {
  secret_id = data.aws_secretsmanager_secret.db-username.id
}

data "aws_secretsmanager_secret" "google-clientid" {
  name = var.googleauth_name
}
data "aws_secretsmanager_secret_version" "google-clientid-secret-version" {
  secret_id = data.aws_secretsmanager_secret.google-clientid.id
}



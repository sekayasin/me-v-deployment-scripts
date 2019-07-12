resource "google_compute_backend_service" "web" {
  name        = "${var.env_name}-vof-lb"
  description = "VOF Load Balancer"
  port_name   = "customhttps"
  protocol    = "HTTPS"
  timeout_sec = 120
  enable_cdn  = false

  backend {
    group = "${google_compute_instance_group_manager.vof-app-server-group-manager.instance_group}"
  }

  session_affinity = "GENERATED_COOKIE"

  health_checks = ["${google_compute_https_health_check.vof-app-healthcheck.self_link}"]
}

resource "google_compute_instance_group_manager" "vof-app-server-group-manager" {
  name               = "${var.env_name}-vof-app-server-group-manager"
  base_instance_name = "${var.env_name}-vof-app-instance"
  instance_template  = "${google_compute_instance_template.vof-app-server-template.self_link}"
  zone               = "${var.zone}"
  update_strategy    = "NONE"

  named_port {
    name = "customhttps"
    port = 8080
  }
}

resource "google_compute_instance_template" "vof-app-server-template" {
  name_prefix          = "${var.env_name}-vof-app-server-template-"
  machine_type         = "${var.machine_type}"
  region               = "${var.region}"
  description          = "Base template to create VOF instances"
  instance_description = "Instance created from base template"
  depends_on           = ["google_sql_database_instance.vof-database-instance", "random_id.vof-db-user-password"]
  tags                 = ["${var.env_name}-vof-app-server", "vof-app-server"]

  network_interface {
    subnetwork    = "${google_compute_subnetwork.vof-private-subnetwork.name}"
    access_config = {}
  }

  disk {
    source_image = "${var.vof_disk_image}"
    auto_delete  = true
    boot         = true
    disk_type    = "${var.vof_disk_type}"
    disk_size_gb = "${var.vof_disk_size}"
  }

  metadata {
    bugsnagKey                             = "${var.bugsnag_key}"
    cableURL                               = "${var.cable_url}"
    databaseUser                           = "${random_id.vof-db-user.b64}"
    databasePassword                       = "${random_id.vof-db-user-password.b64}"
    databaseInstanceName                   = "${var.env_name}-vof-database-instance-${replace(lower(random_id.db-name.b64), "_", "-")}"
    databaseHost                           = "${google_sql_database_instance.vof-database-instance.ip_address.0.ip_address}"
    databasePort                           = "5432"
    databaseName                           = "${var.env_name}-vof-database"
    redisIp                                = "${google_compute_address.redis-ip.address}:6379"
    railsEnv                               = "${var.env_name}"
    bucketName                             = "${var.bucket}"
    slackChannel                           = "${var.slack_channel}"
    slackWebhook                           = "${var.slack_webhook_url}"
    startup-script                         = "/home/vof/start_vof.sh"
    serial-port-enable                     = 1
    userMicroserviceApiUrl                 = "${var.user_microservice_api_url}"
    userMicroserviceApiToken               = "${var.user_microservice_api_token}"
    googleStorageAccessKeyId               = "${var.google_storage_access_key_id}"
    googleStorageSecretAccessKey           = "${var.google_storage_secret_access_key}"
    dbBackupNotificationToken              = "${var.db_backup_notification_token}"
    andelaMicroPublicKey                   = "${var.andela_micro_public_key}"
    learnerMicroPublicKey                  = "${var.learner_micro_public_key}"
    mailgunApiKey                          = "${var.mailgun_api_key}"
    mailgunDomainName                      = "${var.mailgun_domain_name}"
    freshchatToken                         = "${var.freshchat_token}"
    defStorageClass                        = "${var.def_storage_class}"
    storageClass                           = "${var.storage_class}"
    bucketObjectAge                        = "${var.bucket_object_age}"
  }

  lifecycle {
    create_before_destroy = true
  }

  # the email is the service account email whose service keys have all the roles suffiecient enough
  # for the project to interract with all the APIs it does interract with.
  # the scopes are those that we need for logging and monitoring, they are a must for logging to
  # be carried out.
  # the whole service account argument is required for identity and authentication reasons, if it is
  # not included here, the default service account is used instead.
  service_account {
    email = "${var.service_account_email}"

    scopes = ["https://www.googleapis.com/auth/monitoring.write", "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/logging.read",
      "https://www.googleapis.com/auth/logging.write",
    ]
  }
}

resource "google_compute_autoscaler" "vof-app-autoscaler" {
  name   = "${var.env_name}-vof-app-autoscaler"
  zone   = "${var.zone}"
  target = "${google_compute_instance_group_manager.vof-app-server-group-manager.self_link}"

  autoscaling_policy = {
    max_replicas    = "${var.max_instances}"
    min_replicas    = "${var.min_instances}"
    cooldown_period = 60

    cpu_utilization {
      target = 0.7
    }
  }
}

resource "google_compute_https_health_check" "vof-app-healthcheck" {
  name                = "${var.env_name}-vof-app-healthcheck"
  port                = 8080
  request_path        = "${var.request_path}"
  check_interval_sec  = "${var.check_interval_sec}"
  timeout_sec         = "${var.timeout_sec}"
  unhealthy_threshold = "${var.unhealthy_threshold}"
  healthy_threshold   = "${var.healthy_threshold}"
}

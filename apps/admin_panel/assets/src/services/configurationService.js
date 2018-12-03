import { authenticatedRequest } from './apiService'

export function getConfiguration ({ perPage, sort, page, matchAll, matchAny }) {
  return authenticatedRequest({
    path: '/configuration.all',
    data: {
      per_page: perPage,
      sort_by: sort.by,
      sort_dir: sort.dir,
      match_all: matchAll,
      match_any: matchAny
    }
  })
}

export function updateConfiguration ({
  baseUrl,
  redirectUrlPrefixes,
  enableStandalone,
  maxPerPage,
  minPasswordLength,
  senderEmail,
  emailAdapter,
  smtpHost,
  smtpPort,
  smtpUsername,
  smtpPassword,
  fileStorageAdapter,
  gcsBucket,
  gcsCredentials,
  awsBucket,
  awsRegion,
  awsAccessKeyId,
  awsSecretAccessKey,
  balanceCachingStrategy
}) {
  return authenticatedRequest({
    path: '/configuration.update',
    data: {
      base_url: baseUrl,
      redirect_url_prefixes: redirectUrlPrefixes,
      enable_standalone: enableStandalone,
      max_per_page: maxPerPage,
      min_password_length: minPasswordLength,
      sender_email: senderEmail,
      email_adapter: emailAdapter,
      smtp_host: smtpHost,
      smtp_port: smtpPort,
      smtp_username: smtpUsername,
      smtp_password: smtpPassword,
      file_storage_adapter: fileStorageAdapter,
      gcs_bucket: gcsBucket,
      gcs_credentials: gcsCredentials,
      aws_bucket: awsBucket,
      aws_region: awsRegion,
      aws_access_key_id: awsAccessKeyId,
      aws_secret_access_key: awsSecretAccessKey,
      balance_caching_strategy: balanceCachingStrategy
    }
  })
}

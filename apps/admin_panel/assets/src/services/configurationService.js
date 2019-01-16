import { authenticatedRequest } from './apiService'
import _ from 'lodash'
export function getConfiguration () {
  return authenticatedRequest({
    path: '/configuration.all'
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
  balanceCachingStrategy,
  forgetPasswordRequestLifetime
}) {
  const omittedObject = _.omitBy(
    {
      base_url: baseUrl,
      redirect_url_prefixes: Array.isArray(redirectUrlPrefixes)
        ? redirectUrlPrefixes
        : _.isNil(redirectUrlPrefixes)
        ? null
        : [redirectUrlPrefixes],
      enable_standalone: enableStandalone,
      max_per_page: Number(maxPerPage),
      min_password_length: Number(minPasswordLength),
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
      balance_caching_strategy: balanceCachingStrategy,
      forget_password_request_lifetime: Number(forgetPasswordRequestLifetime)
    },
    value => _.isNil(value) || _.isNaN(value) || 0 || ''
  )
  return authenticatedRequest({
    path: '/configuration.update',
    data: omittedObject
  })
}

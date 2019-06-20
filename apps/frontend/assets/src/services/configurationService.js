import _ from 'lodash'
import { authenticatedRequest } from './apiService'
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
  balanceCachingResetFrequency,
  forgetPasswordRequestLifetime,
  masterAccount,
  authTokenLifetime,
  preAuthTokenLifetime
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
      balance_caching_reset_frequency: Number(balanceCachingResetFrequency),
      forget_password_request_lifetime: Number(forgetPasswordRequestLifetime),
      master_account: masterAccount,
      auth_token_lifetime: Number(authTokenLifetime),
      pre_auth_token_lifetime: Number(preAuthTokenLifetime)
    },
    value => _.isNil(value) || _.isNaN(value) || value === 0
  )
  return authenticatedRequest({
    path: '/configuration.update',
    data: omittedObject
  })
}

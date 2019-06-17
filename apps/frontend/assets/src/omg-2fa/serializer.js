export function to2FaFormat ({ label, secret_2fa_code, issuer }) {
  return encodeURI(
    `otpauth://totp/${issuer}:${label}?secret=${secret_2fa_code}&issuer=${issuer}`
  )
}

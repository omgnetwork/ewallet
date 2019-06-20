import history from '../routes/history'

export default () => next => action => {
  if (
    /FAILED/.test(action.type) &&
    _.get(action, 'error.code') === 'user:auth_token_expired'
  ) {
    history.push('/login')
  }
  return next(action)
}

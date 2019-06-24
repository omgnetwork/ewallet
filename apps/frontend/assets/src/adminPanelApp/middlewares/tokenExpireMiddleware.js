import history from '../routes/history'

export default store => next => action => {
  if (
    /FAILED/.test(action.type) &&
    _.get(action, 'error.code') === 'user:auth_token_expired'
  ) {
    history.push('/login')
    store.dispatch({
      type: 'TOKEN_EXPIRE',
      error: 'Token expired, please login again.'
    })
  }
  return next(action)
}

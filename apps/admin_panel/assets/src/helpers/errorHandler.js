import { push } from 'react-router-redux';

import AlertActions from '../actions/alert.actions';

function handleAPIError(dispatch, error) {
  const authenticationErrors = ['user:access_token_not_found'];
  if (authenticationErrors.includes(error.code)) {
    dispatch(push('/signin'));
  } else {
    dispatch(AlertActions.error(error.description));
  }
}

export default handleAPIError;

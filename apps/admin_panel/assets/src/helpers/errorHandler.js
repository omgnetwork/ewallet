import { push } from "react-router-redux";

import { alertActions } from "../actions";

export function handleAPIError(dispatch, error) {
  const authenticationErrors = ["user:access_token_not_found"]
  if (authenticationErrors.includes(error.code)) {
    dispatch(push("/signin"));
  } else {
    dispatch(alertActions.error(error.description));
  }
}

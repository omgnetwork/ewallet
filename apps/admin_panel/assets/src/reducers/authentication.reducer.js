import { userConstants } from "../constants";

export function authentication(state = {}, action) {
  switch (action.type) {
  case userConstants.LOGIN_REQUEST:
    return {
      loggingIn: true
    };
  case userConstants.LOGIN_SUCCESS:
    return {};
  case userConstants.LOGIN_FAILURE:
    return {};

  case userConstants.LOGOUT_REQUEST:
    return {
      loggingOut: true
    };
  case userConstants.LOGOUT_SUCCESS:
    return {};
  case userConstants.LOGOUT_FAILURE:
    return {};
  default:
    return state;
  }
}

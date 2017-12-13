import { userConstants } from "../constants";

export function authentication(state = {loggingIn:false, loggingOut:false}, action) {
  switch (action.type) {
  case userConstants.LOGIN_REQUEST:
    return {
      loggingIn: true
    };
  case userConstants.LOGIN_SUCCESS:
    return {
      loggingIn: false
    };
  case userConstants.LOGIN_FAILURE:
    return {
      loggingIn: false
    };
  case userConstants.LOGOUT_REQUEST:
    return {
      loggingOut: true
    };
  case userConstants.LOGOUT_SUCCESS:
    return {
      loggingOut: false
    };
  case userConstants.LOGOUT_FAILURE:
    return {
      loggingOut: false
    };
  default:
    return state;
  }
}

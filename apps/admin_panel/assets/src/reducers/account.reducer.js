import { accountConstants } from "../constants";

export function account(state = { accounts: [], requesting: false }, action) {
  switch (action.type) {
  case accountConstants.ACCOUNT_REQUEST:
    return {
      accounts: [],
      requesting: true
    };
  case accountConstants.ACCOUNT_SUCCESS:
    return {
      accounts: action.accounts,
      requesting: false
    };
  case accountConstants.ACCOUNT_FAILURE:
    return {
      accounts: [],
      requesting: false
    };
  default:
    return state;
  }
}

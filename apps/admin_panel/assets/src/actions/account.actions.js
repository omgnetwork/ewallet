import { accountConstants } from "../constants";
import { accountAPI } from "../omisego/services";
import { alertActions } from "./";
import { handleAPIError } from "../helpers/errorHandler"

export const accountActions = {
  getAll
};

function getAll() {
  return dispatch => {
    dispatch({ type: accountConstants.ACCOUNT_REQUEST });
    accountAPI.getAll()
      .then(
        accounts => {
          dispatch({ type: accountConstants.ACCOUNT_SUCCESS, accounts });
        },
        error => {
          handleAPIError(dispatch, error)
          dispatch({ type: accountConstants.ACCOUNT_FAILURE, error });
        }
      );
  };
}

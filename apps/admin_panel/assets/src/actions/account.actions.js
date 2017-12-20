import { handleAPIError } from "../helpers/errorHandler"
import { globalActions } from "./";
import { accountAPI } from "../omisego/services";

export const accountActions = {
  loadAccounts,
  createAccount
}

function loadAccounts(query, onSuccess) {
  return dispatch => {
    dispatch(globalActions.showLoading())
    accountAPI.getAll(query)
      .then(
        accounts => {
          onSuccess(accounts)
        },
        error => {
          handleAPIError(dispatch, error)
        }
      ).then(() => {
        dispatch(globalActions.hideLoading())
      });
   };
}

function createAccount(name, description, onSuccess) {
  return dispatch => {
    dispatch(globalActions.showLoading())
    accountAPI.create(name, description)
      .then(
        account => {
          onSuccess(account)
        },
        error => {
          handleAPIError(dispatch, error)
        }
      ).then(() => {
        dispatch(globalActions.hideLoading())
      });
   };
}

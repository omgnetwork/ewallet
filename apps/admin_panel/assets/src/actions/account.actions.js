import { handleAPIError } from "../helpers/errorHandler"
import { globalActions } from "./";
import { accountAPI } from "../omisego/services";

export const accountActions = {
  loadAccounts,
  createAccount
}

function loadAccounts(query, page, per, onSuccess) {
  return dispatch => {
    dispatch(globalActions.showLoading())
    accountAPI.getAll(query, page, per)
      .then(
        accounts => {
          // DUMMY pagination (until server is ready)
          const pagination = {
            currentPage: 1,
            per: 5,
            isLastPage: false,
            isFirstPage: true
          }
          onSuccess(accounts, pagination)
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

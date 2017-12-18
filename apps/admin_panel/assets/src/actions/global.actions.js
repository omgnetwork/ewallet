import { globalConstants } from "../constants";

export const globalActions = {
  showLoading,
  hideLoading
};

function showLoading() {
  return dispatch => {
    dispatch({ type: globalConstants.SHOW_LOADING });
  };
}

function hideLoading() {
  return dispatch => {
    dispatch({ type: globalConstants.HIDE_LOADING });
  };
}

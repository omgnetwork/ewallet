import { globalConstants } from '../constants';
import { urlFormatter } from '../helpers';
import { PAGINATION } from '../helpers/constants';

export const loadingActions = {
  showLoading,
  hideLoading,
};

function showLoading() {
  return (dispatch) => {
    dispatch({ type: globalConstants.SHOW_LOADING });
  };
}

function hideLoading() {
  return (dispatch) => {
    dispatch({ type: globalConstants.HIDE_LOADING });
  };
}

export const urlActions = {
  updateURL,
  processURLParams,
}

function updateURL(push, url, params = {}) {
  push(urlFormatter.formatURL(url, params));
}

function processURLParams(location, onCompleted) {
  const params = urlFormatter.processURL(location);
  const query = params.query ? params.query : '';
  const page = params.page ? parseInt(params.page, 10) : PAGINATION.PAGE;
  const per = params.per ? Math.min(parseInt(params.per, 10), PAGINATION.PER) : PAGINATION.PER;
  onCompleted({ query, page, per });
}

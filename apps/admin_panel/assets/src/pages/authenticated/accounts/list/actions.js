import { handleAPIError } from '../../../../helpers/errorHandler';
import { accountAPI } from '../../../../omisego/services';
import { loadingActions } from '../../../../actions/global.actions';
import { urlFormatter } from '../../../../helpers';
import { PAGINATION } from '../../../../helpers/constants';

class Actions {
  static loadAccounts(params, onSuccess) {
    return (dispatch) => {
      dispatch(loadingActions.showLoading());
      accountAPI.getAll(params, (err, results) => {
        dispatch(loadingActions.hideLoading());
        if (err) {
          handleAPIError(dispatch, err);
        } else {
          const pagination = {
            currentPage: 1,
            per: 5,
            isLastPage: false,
            isFirstPage: true,
          };
          onSuccess(results, pagination);
        }
      });
    };
  }

  static processURLParams(location, onCompleted) {
    const params = urlFormatter.processURL(location);
    const query = params.q ? params.q : '';
    const currentPage = params.page ? parseInt(params.page, 10) : PAGINATION.PAGE;
    const per = params.per ? Math.min(parseInt(params.per, 10), PAGINATION.PER) : PAGINATION.PER;
    onCompleted({ query, currentPage, per });
  }

  static updateURL(push, url, params = {}) {
    push(urlFormatter.formatURL(url, params));
  }
}

export default Actions;

/* eslint no-restricted-syntax: 0 */
import ErrorHandler from '../helpers/errorHandler';
import LoadingActions from '../actions/loading.actions';

const defaultOptions = {
  params: {},
  service: () => { },
  callback: {
    onSuccess: () => { },
    onFail: () => { },
  },
  actions: [],
};

const call = requestOptions => (dispatch) => {
  const callback = {
    onSuccess: () => { },
    onFail: () => { },
    ...requestOptions.callback,
  };
  const { params, service, actions } = {
    ...defaultOptions,
    ...requestOptions,
  };

  dispatch(LoadingActions.showLoading());

  /* execute the omisego's service */
  service(params, (err, result) => {
    dispatch(LoadingActions.hideLoading());
    if (err) {
      /* Global error handler */
      ErrorHandler.handleAPIError(dispatch, err);

      /* Pass the failed result to the component */
      callback.onFail(err);
    } else {
      /* Pass the successful result to the component */
      callback.onSuccess(result);

      /* Dispatch the action to notify data set changes in the redux store */
      for (const action of actions) {
        dispatch(action(result));
      }
    }
  });
};

export default call;

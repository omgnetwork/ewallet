import globalConstants from '../constants/global.constants';

class LoadingActions {
  static showLoading() {
    return (dispatch) => {
      dispatch({ type: globalConstants.SHOW_LOADING });
    };
  }

  static hideLoading() {
    return (dispatch) => {
      dispatch({ type: globalConstants.HIDE_LOADING });
    };
  }
}

export default LoadingActions;

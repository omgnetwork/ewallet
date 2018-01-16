import globalConstants from '../constants/global.constants';

class LoadingActions {
  static showLoading() {
    return { type: globalConstants.SHOW_LOADING };
  }

  static hideLoading() {
    return { type: globalConstants.HIDE_LOADING };
  }
}

export default LoadingActions;

import alertConstants from '../constants/alert.constants';

class AlertActions {
  static success(message) {
    return { type: alertConstants.SUCCESS, message };
  }

  static error(message) {
    return { type: alertConstants.ERROR, message };
  }

  static info(message) {
    return { type: alertConstants.INFO, message };
  }

  static clear() {
    return { type: alertConstants.CLEAR };
  }
}

export default AlertActions;

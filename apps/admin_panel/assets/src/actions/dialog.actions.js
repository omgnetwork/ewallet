import dialogConstants from '../constants/dialog.constants';

class DialogActions {
  static show() {
    return { type: dialogConstants.SHOW_DIALOG };
  }

  static hide() {
    return { type: dialogConstants.HIDE_DIALOG };
  }

  static update(text, actions) {
    return { type: dialogConstants.UPDATE_DIALOG, text, actions };
  }
}

export default DialogActions;

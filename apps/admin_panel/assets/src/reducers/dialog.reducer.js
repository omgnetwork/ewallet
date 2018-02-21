import dialogConstants from '../constants/dialog.constants';

export default function dialog(state = {
  isShow: false,
  text: {
    title: '',
    body: '',
    ok: '',
    cancel: '',
  },
  actions: {
    ok: () => {},
  },
}, action) {
  switch (action.type) {
    case dialogConstants.SHOW_DIALOG:
      return {
        ...state,
        isShow: true,
      };
    case dialogConstants.HIDE_DIALOG:
      return {
        ...state,
        isShow: false,
      };
    case dialogConstants.UPDATE_DIALOG:
      return {
        ...state,
        text: action.text,
        actions: {
          ok: action.actions.ok,
        },
      };
    default:
      return state;
  }
}

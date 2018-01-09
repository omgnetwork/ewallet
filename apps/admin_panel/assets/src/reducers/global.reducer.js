import globalConstants from '../constants/global.constants';

export default function global(state = { loading: false }, action) {
  switch (action.type) {
    case globalConstants.SHOW_LOADING:
      return {
        ...state,
        loading: true,
      };
    case globalConstants.HIDE_LOADING:
      return {
        ...state,
        loading: false,
      };
    default:
      return state;
  }
}

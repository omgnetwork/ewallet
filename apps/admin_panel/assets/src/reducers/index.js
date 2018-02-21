import { combineReducers } from 'redux';
import { routerReducer as router } from 'react-router-redux';
import { localeReducer as locale } from 'react-localize-redux';

import alert from './alert.reducer';
import dialog from './dialog.reducer';
import global from './global.reducer';
import session from './session.reducer';

const rootReducer = combineReducers({
  router,
  locale,
  alert,
  dialog,
  global,
  session,
});

export default rootReducer;

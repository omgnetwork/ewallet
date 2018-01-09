import { combineReducers } from 'redux';
import { sessionReducer } from 'redux-react-session';
import { routerReducer } from 'react-router-redux';
import { localeReducer as locale } from 'react-localize-redux';

import alert from './alert.reducer';
import global from './global.reducer';

const rootReducer = combineReducers({
  session: sessionReducer,
  router: routerReducer,
  alert,
  global,
  locale,
});

export default rootReducer;

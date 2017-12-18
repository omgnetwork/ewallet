import { combineReducers } from "redux";
import { sessionService, sessionReducer } from "redux-react-session";
import { routerReducer } from "react-router-redux";
import { localeReducer as locale } from 'react-localize-redux'

import { authentication } from "./authentication.reducer";
import { alert } from "./alert.reducer";
import { global } from "./global.reducer";

const rootReducer = combineReducers({
  session: sessionReducer,
  router: routerReducer,
  authentication,
  alert,
  global,
  locale
});

export default rootReducer;

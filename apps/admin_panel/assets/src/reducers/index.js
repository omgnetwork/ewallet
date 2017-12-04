import { combineReducers } from "redux";
import { sessionService, sessionReducer } from "redux-react-session";
import { routerReducer } from "react-router-redux";

import { authentication } from "./authentication.reducer";
import { alert } from "./alert.reducer";

const rootReducer = combineReducers({
  session: sessionReducer,
  router: routerReducer,
  authentication,
  alert
});

export default rootReducer;

import { createStore, applyMiddleware, compose } from "redux";
import { createLogger } from "redux-logger";
import DevTools from "../containers/DevTools";
import thunkMiddleware from "redux-thunk";
import { sessionService } from "redux-react-session";
import { routerMiddleware } from "react-router-redux";

import rootReducer from "../reducers";
import { history } from "../helpers";

const loggerMiddleware = createLogger();

const routerMid = routerMiddleware(history);

export const store = createStore(
  rootReducer,
  compose(
    applyMiddleware( thunkMiddleware, loggerMiddleware, routerMid),
    DevTools.instrument()
  )
);
sessionService.initSessionService(store, { driver: "COOKIES" });

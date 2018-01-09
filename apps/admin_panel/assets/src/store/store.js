import { createStore, applyMiddleware, compose } from 'redux';
import { sessionService } from 'redux-react-session';
import { routerMiddleware } from 'react-router-redux';
import thunkMiddleware from 'redux-thunk';
import { createLogger } from 'redux-logger'; // eslint-disable-line import/no-extraneous-dependencies
import { initialize, addTranslationForLanguage } from 'react-localize-redux';
import DevTools from '../pages/DevTools';

import rootReducer from '../reducers';
import history from '../helpers/history';

const routerMid = routerMiddleware(history);
const loggerMiddleware = createLogger();

const store = createStore(
  rootReducer,
  compose(applyMiddleware(thunkMiddleware, loggerMiddleware, routerMid), DevTools.instrument()),
);

sessionService.initSessionService(store, { driver: 'COOKIES' });

const languages = ['en'];
store.dispatch(initialize(languages));
const enLocale = require('../locale/en.json');

store.dispatch(addTranslationForLanguage(enLocale, 'en'));

export default store;

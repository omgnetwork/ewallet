import { createStore, applyMiddleware, compose, combineReducers } from 'redux';
import { routerReducer as router } from 'react-router-redux';
import thunkMiddleware from 'redux-thunk';
import { initialize, addTranslationForLanguage, localeReducer as locale } from 'react-localize-redux';

import alert from '../src/reducers/alert.reducer';
import global from '../src/reducers/global.reducer';
import session from '../src/reducers/session.reducer';

const rootReducer = combineReducers({
  router,
  locale,
  alert,
  global,
  session,
});

const store = createStore(
  rootReducer,
  compose(applyMiddleware(thunkMiddleware)),
);

const languages = ['en'];
store.dispatch(initialize(languages));
const enLocale = require('../src/locale/en.json');

store.dispatch(addTranslationForLanguage(enLocale, 'en'));

export default store;

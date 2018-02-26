import { createStore, applyMiddleware, compose } from 'redux';
import { routerMiddleware } from 'react-router-redux';
import thunkMiddleware from 'redux-thunk';
import { initialize, addTranslationForLanguage } from 'react-localize-redux';

import rootReducer from '../reducers';
import history from '../helpers/history';

const routerMid = routerMiddleware(history);

const store = createStore(
  rootReducer,
  compose(applyMiddleware(thunkMiddleware, routerMid)),
);

const languages = ['en'];
store.dispatch(initialize(languages));
const enLocale = require('../locale/en.json');

store.dispatch(addTranslationForLanguage(enLocale, 'en'));

export default store;

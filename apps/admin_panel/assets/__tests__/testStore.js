import { createStore, applyMiddleware, compose, combineReducers } from 'redux';
import { routerReducer as router } from 'react-router-redux';
import thunkMiddleware from 'redux-thunk';
import { initialize, addTranslationForLanguage, localeReducer as locale } from 'react-localize-redux';

const rootReducer = combineReducers({
  router,
  locale,
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

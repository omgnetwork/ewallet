import buildURL from '../../helpers/urlHelper';
import {
  serverErrorResponse,
  loginSuccessResponse,
  resetPasswordSuccessResponse,
} from './responses.stubs';

import {
  loginValidParams,
  resetPasswordValidParams,
} from './params.stubs';

function formatStub(path, response) {
  return ({ url: buildURL(path), response });
}

export function loginStub(params) {
  return (
    JSON.stringify(params) === JSON.stringify(loginValidParams)
      ? formatStub('login', loginSuccessResponse)
      : formatStub('login', serverErrorResponse)
  );
}

export function resetPasswordStub(params) {
  return (
    JSON.stringify(params) === JSON.stringify(resetPasswordValidParams)
      ? formatStub('password.reset', resetPasswordSuccessResponse)
      : formatStub('password.reset', serverErrorResponse)
  );
}

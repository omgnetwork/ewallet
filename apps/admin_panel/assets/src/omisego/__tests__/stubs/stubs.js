import buildURL from '../../helpers/urlHelper';
import {
  serverErrorResponse,
  loginSuccessResponse,
  forgotPasswordSuccessResponse,
} from './responses.stubs';

import {
  loginValidParams,
  forgotPasswordValidParams,
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

export function forgotPasswordStub(params) {
  return (
    JSON.stringify(params) === JSON.stringify(forgotPasswordValidParams)
      ? formatStub('forgot_password', forgotPasswordSuccessResponse)
      : formatStub('forgot_password', serverErrorResponse)
  );
}

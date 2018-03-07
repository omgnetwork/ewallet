import OmiseGOError from '../models/error';
import mergeHash from '../helpers/helper';
import { OMISEGO_BASE_URL } from '../config';
import buildURL from '../helpers/urlHelper';
import headers from '../helpers/headers';

function requestOptions(body, authenticated) {
  return {
    method: 'POST',
    headers: mergeHash(
      {
        Accept: 'application/vnd.omisego.v1+json',
        'Content-Type': 'application/json',
      },
      headers(authenticated),
    ),
    body,
  };
}

function requestOptionsMultipart(body, authenticated) {
  return {
    method: 'POST',
    headers: mergeHash(
      {
        Accept: 'application/vnd.omisego.v1+json',
      },
      headers(authenticated),
    ),
    body,
  };
}


function handleResponse(response) {
  if ([200, 500].includes(response.status)) {
    return response.json();
  }
  const error = new OmiseGOError({
    code: 'invalid_status_code',
    description: 'Invalid http status code',
  });
  return Promise.reject(error);
}

function parseJson(json) {
  if (json.success) {
    return json.data;
  }
  const error = new OmiseGOError(json.data);
  return Promise.reject(error);
}

function handleError(error) {
  if (error.code == null || error.description == null) {
    throw new OmiseGOError({
      code: 'unknown',
      description: `Could not connect to Admin API (${OMISEGO_BASE_URL})`,
    });
  } else {
    throw error;
  }
}

export default function request({
  path, params, authenticated, isMultipart = false,
}) {
  const url = buildURL(path);
  const options = isMultipart
    ? requestOptionsMultipart(params, authenticated)
    : requestOptions(params, authenticated);

  return fetch(url, options)
    .then(handleResponse)
    .then(parseJson)
    .catch(handleError);
}

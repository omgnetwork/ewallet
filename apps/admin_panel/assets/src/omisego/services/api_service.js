import OmiseGOError from '../models/error';
import mergeHash from '../helpers/helper';
import { OMISEGO_BASE_URL } from '../config';
import authHeader from '../helpers/auth-header';

function requestOptions(body, headers) {
  return {
    method: 'POST',
    headers: mergeHash(
      {
        Accept: 'application/vnd.omisego.v1+json',
        'Content-Type': 'application/json',
      },
      headers,
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
      description: 'Failed to fetch',
    });
  } else {
    throw error;
  }
}

export default function request(path, body, callback) {
  const url = OMISEGO_BASE_URL + path;
  return fetch(url, requestOptions(body, authHeader()))
    .then(handleResponse)
    .then(parseJson)
    .catch(handleError)
    .then(
      (results) => {
        callback(null, results);
      },
      (error) => {
        callback(error, null);
      },
    );
}

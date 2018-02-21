import { getAll, deleteKey } from '../../../../omisego/services/api_management_api';
import call from '../../../../actions/api.actions';

export const loadApiKeys = (params, onSuccess) => call({
  params,
  service: getAll,
  callback: {
    onSuccess,
  },
});

export const deleteApiKey = (params, onSuccess) => call({
  params,
  service: deleteKey,
  callback: {
    onSuccess,
  },
});

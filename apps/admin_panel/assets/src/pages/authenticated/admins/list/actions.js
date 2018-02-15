import { getAll } from '../../../../omisego/services/admin_api';
import SERIALIZER from '../../../../helpers/serializer';
import call from '../../../../actions/api.actions';

const loadAdmins = (params, onSuccess) => call({
  params,
  service: getAll,
  callback: {
    onSuccess: SERIALIZER.LIST_ADMINS(onSuccess),
  },
});

export default loadAdmins;

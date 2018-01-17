import { handleAPIError } from '../../../../helpers/errorHandler';
import getAll from '../../../../omisego/services/admin_api';
import LoadingActions from '../../../../actions/loading.actions';
import dateFormatter from '../../../../helpers/dateFormatter';

class Actions {
  static loadAdmins(params, onSuccess) {
    return (dispatch) => {
      dispatch(LoadingActions.showLoading());
      getAll(params, (err, results) => {
        dispatch(LoadingActions.hideLoading());
        if (err) {
          handleAPIError(dispatch, err);
        } else {
          const selectiveData = results.data.map(v => ({
            id: v.id,
            email: v.email,
            created_at: dateFormatter.format(v.created_at),
            updated_at: dateFormatter.format(v.updated_at),
          }));

          onSuccess(selectiveData, results.pagination);
        }
      });
    };
  }
}

export default Actions;

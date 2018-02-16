import React, { Component } from 'react';
import { getTranslate } from 'react-localize-redux';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import OMGLoadingButton from '../../../components/OMGLoadingButton';
import AlertActions from '../../../actions/alert.actions';
import OMGFieldGroup from '../../../components/OMGFieldGroup';
import OMGPhotoPreviewer from '../../../components/OMGPhotoPreviewer';
import placeholder from '../../../../public/images/user_icon_placeholder.png';
import Actions from './actions';
import { moveToTop } from '../../../helpers/scrollHelper';

class SettingForm extends Component {
  constructor(props) {
    super(props);
    const { currentAccount } = props;
    const { name, avatar } = currentAccount;
    this.state = {
      accountName: name,
      avatar: avatar.small || placeholder,
      avatarFile: null,
      loading: {
        saveAccount: false,
      },
    };
    this.handleFileChanged = this.handleFileChanged.bind(this);
    this.handleFormChanged = this.handleFormChanged.bind(this);
    this.handleUpdateFormSuccess = this.handleUpdateFormSuccess.bind(this);
    this.handleUpdateFormFailed = this.handleUpdateFormFailed.bind(this);
    this.handleUpdateAccount = this.handleUpdateAccount.bind(this);
    this.photoPreviewer = null;
  }

  // Invoke when the user browse and select a new photo.
  handleFileChanged(file) {
    this.setState({
      avatarFile: file,
    });
  }

  // Invoke every time the user type on the input form.
  handleFormChanged(e) {
    const { id, value } = e.target;
    this.setState(
      {
        [id]: value,
      },
      this.validate,
    );
  }

  handleUpdateAccount() {
    const { currentAccount, updateAccount, updateAccountAndAvatar } = this.props;
    const { accountName, avatarFile, loading } = this.state;
    const params = {
      updateAccount: {
        ...currentAccount,
        name: accountName,
      },
      uploadAvatar: {
        accountId: currentAccount.id,
        avatar: avatarFile,
      },
    };

    this.setState({
      loading: {
        ...loading,
        saveAccount: true,
      },
    });

    const uploadable = this.photoPreviewer.shouldImageBeUploaded();

    if (uploadable) {
      updateAccountAndAvatar(params, this.handleUpdateFormSuccess, this.handleUpdateFormFailed);
    } else {
      updateAccount(params.updateAccount, this.handleUpdateFormSuccess);
    }
  }

  handleUpdateFormSuccess(result) {
    const { showSuccessAlert, translate } = this.props;
    showSuccessAlert(translate('setting.form.notification.success.update_account', { name: result.updateAccount.name }));
    this.setState(prevState => ({
      loading: {
        ...prevState.loading,
        saveAccount: false,
      },
      avatarFile: null,
      avatar: (result.uploadAvatar && result.uploadAvatar.avatar.small) || prevState.avatar,
    }));

    moveToTop();
  }

  handleUpdateFormFailed() {
    this.setState(prevState => ({
      loading: {
        ...prevState.loading,
        saveAccount: false,
      },
    }));

    moveToTop();
  }

  handleResendInvitationSuccess(member) {
    const { showSuccessAlert, translate } = this.props;
    showSuccessAlert(translate('setting.form.notification.success.resend_invitation', { email: member.email }));
    moveToTop();
  }

  render() {
    const { translate } = this.props;
    const {
      accountName,
      avatar,
      loading,
    } = this.state;

    const formActions = (
      <div className="mt-3">
        <OMGLoadingButton
          className="btn-omg-blue omg-form__button"
          disabled={!accountName}
          loading={loading.saveAccount}
          onClick={this.handleUpdateAccount}
          type="button"
        >
          {translate('setting.form.save.label')}
        </OMGLoadingButton>
      </div>
    );

    return (
      <div>
        <h1>
          {translate('setting.header.title')}
        </h1>
        <div className="mt-2">
          <h4>
            {translate('setting.header.edit_account')}
          </h4>
          <OMGPhotoPreviewer
            ref={(instance) => { this.photoPreviewer = instance; }}
            img={avatar}
            onFileChanged={this.handleFileChanged}
            showCloseBtn={avatar !== placeholder}
            showUploadBtn={avatar === placeholder}
          />
        </div>
        <div className="mt-1">
          <OMGFieldGroup
            groupClass="form__group omg-form__flex-stretch"
            help=""
            id="accountName"
            label={translate('setting.form.account_name.label')}
            onChange={this.handleFormChanged}
            type="text"
            validationState={null}
            value={accountName}
          />
          {formActions}
        </div>
      </div>
    );
  }
}

SettingForm.propTypes = {
  currentAccount: PropTypes.object.isRequired,
  showSuccessAlert: PropTypes.func.isRequired,
  translate: PropTypes.func.isRequired,
  updateAccount: PropTypes.func.isRequired,
  updateAccountAndAvatar: PropTypes.func.isRequired,
};

function mapStateToProps(state) {
  const { loading } = state.global;
  const translate = getTranslate(state.locale);
  const currentPath = state.router.location.pathname;
  const { currentAccount } = state.session;
  return {
    translate,
    loading,
    currentPath,
    currentAccount,
  };
}

function mapDispatchToProps(dispatch) {
  return {
    updateAccount: (member, onSuccess) => {
      dispatch(Actions.updateAccount(member, onSuccess));
    },
    showSuccessAlert: (message) => {
      dispatch(AlertActions.success(message));
    },
    updateAccountAndAvatar: (params, onSuccess, onFailed) => {
      dispatch(Actions.updateAccountAndAvatar(params, onSuccess, onFailed));
    },
  };
}

export default connect(mapStateToProps, mapDispatchToProps)(SettingForm);

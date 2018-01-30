import React, { Component } from 'react';
import { withRouter } from 'react-router-dom';
import { getTranslate } from 'react-localize-redux';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import OMGLoadingButton from '../../../components/OMGLoadingButton';
import AlertActions from '../../../actions/alert.actions';
import OMGFieldGroup from '../../../components/OMGFieldGroup';
import OMGPhotoPreviewer from '../../../components/OMGPhotoPreviewer';
import OMGAddMemberForm from '../../../components/OMGAddMemberForm';
import OMGMemberItem from '../../../components/OMGMemberItem';
import PlaceHolder from '../../../../public/images/user_icon_placeholder.png';
import Actions from './actions';

class Setting extends Component {
  constructor(props) {
    super(props);
    const { currentAccount } = props;
    const { name, photoUrl } = currentAccount;
    this.state = {
      editId: 0,
      accountName: name,
      photoUrl: photoUrl || PlaceHolder,
      photoFile: null,
      memberList: [],
      loading: {
        saveAccount: false,
        addMember: false,
        updateMember: false,
        removeMember: false,
      },
    };
    this.handleFileChanged = this.handleFileChanged.bind(this);
    this.handleFormChanged = this.handleFormChanged.bind(this);
    this.handleEditClick = this.handleEditClick.bind(this);
    this.handleResendClick = this.handleResendClick.bind(this);
    this.handleCancelClick = this.handleCancelClick.bind(this);
    this.handleSyncMember = this.handleSyncMember.bind(this);
    this.reloadMembers = this.reloadMembers.bind(this);
    this.handleUpdateFormSuccess = this.handleUpdateFormSuccess.bind(this);
    this.handleResendInvitationSuccess = this.handleResendInvitationSuccess.bind(this);
    this.handleSearchUsers = this.handleSearchUsers.bind(this);
    this.handleUpdateAccount = this.handleUpdateAccount.bind(this);
  }

  componentDidMount() {
    const { listMemberInAccount, currentAccount } = this.props;
    listMemberInAccount({ accountId: currentAccount.id }, this.reloadMembers);
  }

  // Invoke when the user browse and select a new photo.
  handleFileChanged(file) {
    this.setState({
      photoFile: file,
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

  handleSyncMember(targetMember, actionType) {
    const { add, update, remove } = OMGAddMemberForm.actionType();
    const {
      currentAccount, assignMember, unassignMember, inviteMember,
    } = this.props;
    const { memberList } = this.state;
    const updatingMember = memberList.filter(member => member.email === targetMember.email)[0];
    switch (actionType) {
      case add:
        if (targetMember.status === 'pending_confirmation') {
          inviteMember({
            email: targetMember.email,
            accountId: currentAccount.id,
            roleName: targetMember.accountRole.toLowerCase(),
          }, () => {
            this.handleResendInvitationSuccess(targetMember);
            this.reloadMembers();
          });
        } else {
          assignMember({
            accountId: currentAccount.id,
            userId: targetMember.id,
            roleName: targetMember.accountRole.toLowerCase(),
          }, this.reloadMembers);
        }
        this.setState(prevState => ({
          loading: {
            ...prevState.loading,
            addMember: true,
          },
        }));
        break;
      case update:
        assignMember({
          accountId: currentAccount.id,
          userId: updatingMember.id,
          roleName: targetMember.accountRole.toLowerCase(),
        }, this.reloadMembers);
        this.setState(prevState => ({
          loading: {
            ...prevState.loading,
            updateMember: true,
          },
        }));
        break;
      case remove:
        unassignMember({
          accountId: currentAccount.id,
          userId: targetMember.id,
        }, this.reloadMembers);
        this.setState(prevState => ({
          loading: {
            ...prevState.loading,
            removeMember: true,
          },
        }));
        break;
      default:
    }
  }

  handleSearchUsers(query, callback) {
    const { searchUsers } = this.props;
    const params = {
      per: 5,
      sort: {
        by: 'email',
        dir: 'asc',
      },
      query,
    };
    searchUsers(params, callback);
  }

  reloadMembers() {
    const { currentAccount, listMemberInAccount } = this.props;
    listMemberInAccount({ accountId: currentAccount.id }, (memberList) => {
      // const nonNullEmailMembers = memberList.filter(member => member.email);
      this.setState(prevState => ({
        memberList,
        editId: 0,
        loading: {
          ...prevState.loading,
          addMember: false,
          updateMember: false,
          removeMember: false,
        },
      }));
    });
  }

  handleUpdateFormSuccess(account) {
    const { showSuccessAlert, translate } = this.props;
    showSuccessAlert(translate('setting.form.notification.success.update_account', { name: account.name }));
    this.setState(prevState => ({
      loading: {
        ...prevState.loading,
        saveAccount: false,
      },
    }));

    // Go to the top of the page to see the notification
    window.scrollTo(0, 0);
  }

  handleResendInvitationSuccess(member) {
    const { showSuccessAlert, translate } = this.props;
    showSuccessAlert(translate('setting.form.notification.success.resend_invitation', { email: member.email }));
    // Go to the top of the page to see the notification
    window.scrollTo(0, 0);
  }

  handleUpdateAccount() {
    const { currentAccount, updateAccount } = this.props;
    const { accountName } = this.state;
    const params = {
      ...currentAccount,
      name: accountName,
    };
    updateAccount(params, this.handleUpdateFormSuccess);
    this.setState(prevState => ({
      loading: {
        ...prevState.loading,
        saveAccount: true,
      },
    }));
  }

  handleCancelClick() {
    this.setState({
      editId: 0,
    });
  }

  handleEditClick(member) {
    this.setState({
      editId: member.id,
    });
  }

  handleResendClick(targetMember) {
    const { currentAccount, inviteMember } = this.props;
    inviteMember({
      email: targetMember.email,
      accountId: currentAccount.id,
      roleName: targetMember.accountRole.toLowerCase(),
    }, this.handleResendInvitationSuccess);
  }

  render() {
    const { translate, currentPath } = this.props;
    const {
      accountName,
      photoUrl,
      memberList,
      editId,
      loading,
    } = this.state;

    const memberItems = memberList.map((member) => {
      if (member.id !== editId) {
        return (<OMGMemberItem
          key={member.id}
          currentPath={currentPath}
          member={{ ...member, isPending: member.status === 'pending_confirmation' }}
          onEdit={this.handleEditClick}
          onResend={this.handleResendClick}
        />);
      }
      return (
        <OMGAddMemberForm
          key={member.id}
          isDisabledTextInput
          isEdit
          labelKey="email"
          loading={loading}
          member={member}
          onCancel={this.handleCancelClick}
          onRemove={this.handleSyncMember}
          onUpdate={this.handleSyncMember}
          roles={[
            { label: 'setting.form.roles.admin', value: 'admin' },
            { label: 'setting.form.roles.viewer', value: 'viewer' },
          ]}
        />
      );
    });

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
      <div className="row">
        <div className="col-xs-12 col-sm-6">
          <div className="omg-form">
            <h1>
              {translate('setting.header.setting')}
            </h1>
            <div className="mt-2">
              <h4>
                {translate('setting.header.edit_account')}
              </h4>
              <OMGPhotoPreviewer
                img={photoUrl}
                onFileChanged={this.handleFileChanged}
                showCloseBtn={photoUrl !== PlaceHolder}
                showUploadBtn={photoUrl === PlaceHolder}
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
            <div className="mb-1 mt-3">
              <h4>
                {translate('setting.form.assign_team_member.label')}
              </h4>
            </div>
            <OMGAddMemberForm
              labelKey="email"
              loading={loading}
              onAdd={this.handleSyncMember}
              onSearch={this.handleSearchUsers}
              roles={[
                { label: 'setting.form.roles.admin', value: 'admin' },
                { label: 'setting.form.roles.viewer', value: 'viewer' },
              ]}
            />
            {memberItems}
            <div className="mt-3 omg-hide">
              <h4>
                {translate('setting.form.remove_account.label')}
                <a className="omg-member-item__edit" href="#remove">
                  {translate('setting.form.remove.label')}
                </a>
              </h4>
            </div>
          </div>
        </div>
      </div>
    );
  }
}

Setting.propTypes = {
  assignMember: PropTypes.func.isRequired,
  currentAccount: PropTypes.object.isRequired,
  currentPath: PropTypes.string.isRequired,
  inviteMember: PropTypes.func.isRequired,
  listMemberInAccount: PropTypes.func.isRequired,
  searchUsers: PropTypes.func.isRequired,
  showSuccessAlert: PropTypes.func.isRequired,
  translate: PropTypes.func.isRequired,
  unassignMember: PropTypes.func.isRequired,
  updateAccount: PropTypes.func.isRequired,
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
    assignMember: (member, onSuccess) => {
      dispatch(Actions.assignMember(member, onSuccess));
    },
    inviteMember: (member, onSuccess) => {
      dispatch(Actions.inviteMember(member, onSuccess));
    },
    listMemberInAccount: (params, onSuccess) => {
      dispatch(Actions.listMembers(params, onSuccess));
    },
    searchUsers: (params, onSuccess) => {
      dispatch(Actions.searchUsers(params, onSuccess));
    },
    unassignMember: (member, onSuccess) => {
      dispatch(Actions.unassignMember(member, onSuccess));
    },
    showSuccessAlert: (message) => {
      dispatch(AlertActions.success(message));
    },
  };
}

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(Setting));

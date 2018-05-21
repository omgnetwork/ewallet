import React, { Component } from 'react';
import { withRouter } from 'react-router-dom';
import { getTranslate } from 'react-localize-redux';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import AlertActions from '../../../actions/alert.actions';
import OMGAddMemberForm from '../../../components/OMGAddMemberForm';
import OMGMemberItem from '../../../components/OMGMemberItem';
import Actions from './actions';
import { moveToTop } from '../../../helpers/scrollHelper';
import { formatEmailLink } from '../../../helpers/urlFormatter';

class SettingInvitation extends Component {
  constructor(props) {
    super(props);
    this.state = {
      editId: 0,
      memberList: [],
      loading: {
        addMember: false,
        updateMember: false,
        removeMember: false,
      },
    };
    this.handleEditClick = this.handleEditClick.bind(this);
    this.handleResendClick = this.handleResendClick.bind(this);
    this.handleCancelClick = this.handleCancelClick.bind(this);
    this.handleSyncMember = this.handleSyncMember.bind(this);
    this.reloadMembers = this.reloadMembers.bind(this);
    this.handleResendInvitationSuccess = this.handleResendInvitationSuccess.bind(this);
    this.handleSearchUsers = this.handleSearchUsers.bind(this);
  }

  componentDidMount() {
    const { listMemberInAccount, currentAccount } = this.props;
    listMemberInAccount({ accountId: currentAccount.id }, this.reloadMembers);
  }

  handleSyncMember(targetMember, actionType) {
    const { add, update, remove } = OMGAddMemberForm.actionType();
    const {
      currentAccount, assignMember, unassignMember, invitation, inviteMember,
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
            url: formatEmailLink(invitation),
          }, () => {
            this.handleResendInvitationSuccess(targetMember);
            this.reloadMembers();
          });
        } else {
          assignMember({
            accountId: currentAccount.id,
            userId: targetMember.id,
            roleName: targetMember.accountRole.toLowerCase(),
            url: formatEmailLink(invitation),
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
          url: formatEmailLink(invitation),
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

  handleResendInvitationSuccess(member) {
    const { showSuccessAlert, translate } = this.props;
    showSuccessAlert(translate('setting.form.notification.success.resend_invitation', { email: member.email }));
    moveToTop();
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
    const { currentAccount, invitation, inviteMember } = this.props;
    inviteMember({
      email: targetMember.email,
      accountId: currentAccount.id,
      roleName: targetMember.accountRole.toLowerCase(),
      url: formatEmailLink(invitation),
    }, this.handleResendInvitationSuccess);
  }

  render() {
    const { translate, currentPath } = this.props;
    const {
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
    return (
      <div>
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
    );
  }
}

SettingInvitation.propTypes = {
  assignMember: PropTypes.func.isRequired,
  currentAccount: PropTypes.object.isRequired,
  currentPath: PropTypes.string.isRequired,
  invitation: PropTypes.object.isRequired,
  inviteMember: PropTypes.func.isRequired,
  listMemberInAccount: PropTypes.func.isRequired,
  searchUsers: PropTypes.func.isRequired,
  showSuccessAlert: PropTypes.func.isRequired,
  translate: PropTypes.func.isRequired,
  unassignMember: PropTypes.func.isRequired,
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
    assignMember: (member, onSuccess) => {
      dispatch(Actions.assignMember(member, onSuccess));
    },
    inviteMember: (params, onSuccess) => {
      dispatch(Actions.inviteMember(params, onSuccess));
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

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(SettingInvitation));

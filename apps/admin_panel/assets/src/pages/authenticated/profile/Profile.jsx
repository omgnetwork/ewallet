import React, { Component } from 'react';
import { withRouter } from 'react-router-dom';
import { getTranslate } from 'react-localize-redux';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import Actions from './actions';
import AlertActions from '../../../actions/alert.actions';
import OMGFieldGroup from '../../../components/OMGFieldGroup';
import OMGLoadingButton from '../../../components/OMGLoadingButton';
import OMGPhotoPreviewer from '../../../components/OMGPhotoPreviewer';
import placeholder from '../../../../public/images/user_icon_placeholder.png';
import { OMISEGO_BASE_URL } from '../../../omisego/config';
import { moveToTop } from '../../../helpers/scrollHelper';

class Profile extends Component {
  constructor(props) {
    super(props);
    const { session } = props;
    const { currentUser } = session;
    this.state = {
      username: currentUser.username || '',
      email: currentUser.email || '',
      fullName: (currentUser.metadata.first_name + currentUser.metadata.last_name) || '',
      position: currentUser.position || '',
      companyName: currentUser.companyName || '',
      loading: {
        submit: false,
      },
      avatar: currentUser.avatar.small || placeholder,
      avatarFile: null,
    };
    this.handleSubmit = this.handleSubmit.bind(this);
    this.handleFileChanged = this.handleFileChanged.bind(this);
    this.handleFormChanged = this.handleFormChanged.bind(this);
    this.handleUploadAvatarSuccess = this.handleUploadAvatarSuccess.bind(this);
  }

  handleSubmit(e) {
    e.preventDefault();
    const { avatarFile } = this.state;
    const { uploadAvatar, session } = this.props;
    const { currentUser } = session;
    this.setState({ loading: { submit: true } });
    uploadAvatar({
      id: currentUser.id,
      avatar: avatarFile,
    }, this.handleUploadAvatarSuccess);
  }

  handleUploadAvatarSuccess(result) {
    this.setState({
      avatar: `${OMISEGO_BASE_URL}${result.avatar.original.substr(1)}`,
      avatarFile: null,
      loading: {
        submit: false,
      },
    }, () => {
      const { translate, showSuccessAlert } = this.props;
      showSuccessAlert(translate('profile.form.success.upload_avatar'));
      moveToTop();
    });
  }

  handleFileChanged(file) {
    this.setState({
      avatarFile: file,
    });
  }

  handleFormChanged(e) {
    const { id, value } = e.target;
    this.setState({
      [id]: value,
    });
  }

  render() {
    const { translate } = this.props;
    const {
      username, email, fullName, position, companyName, avatar, loading,
    } = this.state;
    return (
      <div className="row mb-3">
        <div className="col-xs-12 col-sm-4">
          <div className="omg-form">
            <h1>
              {translate('profile.header.profile')}
            </h1>
            <form autoComplete="off" onSubmit={this.handleSubmit}>
              <div className="mt-2">
                <h4>
                  Edit Profile
                </h4>
                <OMGPhotoPreviewer
                  img={avatar}
                  onFileChanged={this.handleFileChanged}
                  showCloseBtn={avatar !== placeholder}
                  showUploadBtn={avatar === placeholder}
                />
              </div>
              <OMGFieldGroup
                help=""
                id="username"
                label={translate('profile.form.username.label')}
                onChange={this.handleFormChanged}
                type="text"
                validationState={null}
                value={username}
              />

              <OMGFieldGroup
                help=""
                id="email"
                label={translate('profile.form.email.label')}
                onChange={this.handleFormChanged}
                type="text"
                validationState={null}
                value={email}
              />
              <div style={{ marginTop: 64 }}>
                <OMGFieldGroup
                  help=""
                  id="fullName"
                  label={translate('profile.form.full_name.label')}
                  onChange={this.handleFormChanged}
                  type="text"
                  validationState={null}
                  value={fullName}
                />
                <OMGFieldGroup
                  help=""
                  id="position"
                  label={translate('profile.form.position.label')}
                  onChange={this.handleFormChanged}
                  type="text"
                  validationState={null}
                  value={position}
                />
                <OMGFieldGroup
                  help=""
                  id="companyName"
                  label={translate('profile.form.company_name.label')}
                  onChange={this.handleFormChanged}
                  type="text"
                  validationState={null}
                  value={companyName}
                />
              </div>
              <div>
                <OMGLoadingButton
                  loading={loading.submit}
                  type="submit"
                >
                  {translate('profile.form.submit')}
                </OMGLoadingButton>
              </div>
            </form>
          </div>
        </div>
      </div>
    );
  }
}

Profile.propTypes = {
  session: PropTypes.object.isRequired,
  showSuccessAlert: PropTypes.func.isRequired,
  translate: PropTypes.func.isRequired,
  uploadAvatar: PropTypes.func.isRequired,
};

function mapStateToProps(state) {
  const { loading } = state.global;
  const translate = getTranslate(state.locale);
  const { session } = state;
  return {
    translate,
    loading,
    session,
  };
}

function mapDispatchToProps(dispatch) {
  return {
    uploadAvatar: (params, onSuccess) => {
      dispatch(Actions.uploadAvatar(params, onSuccess));
    },
    showSuccessAlert: (message) => {
      dispatch(AlertActions.success(message));
    },
  };
}

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(Profile));

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
import { ADMIN_API_BASE_URL } from '../../../omisego/config';
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
    this.handleUploadAvatarFailed = this.handleUploadAvatarFailed.bind(this);
    this.photoPreviewer = null;
  }

  handleSubmit(e) {
    e.preventDefault();
    const { avatarFile } = this.state;
    const {
      uploadAvatar, session, showInfoAlert, translate,
    } = this.props;
    const { currentUser } = session;
    const uploadable = this.photoPreviewer.shouldImageBeUploaded();
    if (uploadable) {
      this.setState({ loading: { submit: true } });
      uploadAvatar(
        {
          id: currentUser.id,
          avatar: avatarFile,
        },
        this.handleUploadAvatarSuccess,
        this.handleUploadAvatarFailed,
      );
    } else {
      showInfoAlert(translate('profile.form.notification.upload_info'));
      moveToTop();
    }
  }

  handleUploadAvatarSuccess(result) {
    this.setState({
      avatar: (result.avatar.small && `${ADMIN_API_BASE_URL}${result.avatar.small.substr(1)}`) || placeholder,
      avatarFile: null,
      loading: {
        submit: false,
      },
    }, () => {
      const { translate, showSuccessAlert } = this.props;
      showSuccessAlert(translate('profile.form.notification.upload_avatar'));
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

  handleUploadAvatarFailed() {
    this.setState({
      loading: {
        submit: false,
      },
    });
    moveToTop();
  }

  render() {
    const { translate } = this.props;
    const {
      username, email, fullName, position, companyName, avatar, loading,
    } = this.state;
    return (
      <div className="row mb-3">
        <div className="col-xs-8">
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
                  ref={(instance) => { this.photoPreviewer = instance; }}
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
  showInfoAlert: PropTypes.func.isRequired,
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
    uploadAvatar: (params, onSuccess, onFailed) => {
      dispatch(Actions.uploadAvatar(params, onSuccess, onFailed));
    },
    showSuccessAlert: (message) => {
      dispatch(AlertActions.success(message));
    },
    showInfoAlert: (message) => {
      dispatch(AlertActions.info(message));
    },
  };
}

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(Profile));

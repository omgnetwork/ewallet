import React, { Component } from 'react';
import { withRouter } from 'react-router-dom';
import { getTranslate } from 'react-localize-redux';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import { Button } from 'react-bootstrap';
import OMGFieldGroup from '../../../components/OMGFieldGroup';
import OMGPhotoPreviewer from '../../../components/OMGPhotoPreviewer';
import PlaceHolder from '../../../../public/images/user_icon_placeholder.png';

class Profile extends Component {
  constructor(props) {
    super(props);
    const { currentUser } = props;
    this.state = {
      username: currentUser.username,
      email: currentUser.email,
      fullName: currentUser.fullName,
      position: currentUser.position,
      companyName: currentUser.companyName,
      photoUrl: currentUser.photoUrl ? currentUser.photoUrl : PlaceHolder,
      photoFile: null,
      valid: true,
    };
    this.handleSave = this.handleSave.bind(this);
    this.handleCancel = this.handleCancel.bind(this);
    this.handleFileChanged = this.handleFileChanged.bind(this);
    this.handleFormChanged = this.handleFormChanged.bind(this);
    this.validate = this.validate.bind(this);
  }

  componentDidMount() {
    // Initialize the state by fetching the data from the server here.
  }

  handleSave() {
    console.log(this.state);
  }

  handleCancel() {
    // Go to dashboard
    const { history } = this.props;
    history.push('/');
  }

  handleFileChanged(file) {
    this.setState({
      photoFile: file,
    });
  }

  handleFormChanged(e) {
    const { id, value } = e.target;
    this.setState(
      {
        [id]: value,
      },
      this.validate,
    );
  }

  validate() {
    const valid = true; // TODO: change this to validate each fields, check for loading state, etc.
    this.setState({
      valid,
    });
  }

  render() {
    const { translate } = this.props;
    const {
      username, email, fullName, position, companyName, photoUrl,
    } = this.state;
    return (
      <div className="row">
        <div className="col-xs-12 col-sm-3">
          <div className="omg-form">
            <h1>
              {translate('profile.header.profile')}
            </h1>
            <form autoComplete="off">
              <div className="mt-2">
                <h4>
                  Edit Profile
                </h4>
                <OMGPhotoPreviewer
                  img={photoUrl}
                  onFileChanged={this.handleFileChanged}
                  showCloseBtn={photoUrl !== PlaceHolder}
                  showUploadBtn={photoUrl === PlaceHolder}
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
                <Button
                  bsClass="btn btn-omg-blue"
                  bsStyle="primary"
                  onClick={this.handleSave}
                  type="button"
                >
                  Save
                </Button>
                <Button
                  bsClass="btn btn-omg-white"
                  bsStyle="primary"
                  className="ml-1"
                  onClick={this.handleCancel}
                  type="submit"
                >
                  Cancel
                </Button>
              </div>
            </form>
          </div>
        </div>
      </div>
    );
  }
}

Profile.defaultProps = {
  currentUser: {
    username: '',
    email: '',
    fullName: '',
    position: '',
    companyName: '',
    photoUrl: '',
  },
};

Profile.propTypes = {
  currentUser: PropTypes.shape({
    username: PropTypes.string,
    email: PropTypes.string,
    fullName: PropTypes.string,
    position: PropTypes.string,
    companyName: PropTypes.string,
    photoUrl: PropTypes.string,
  }),
  history: PropTypes.object.isRequired,
  translate: PropTypes.func.isRequired,
};

function mapStateToProps(state) {
  const { loading } = state.global;
  const translate = getTranslate(state.locale);
  return {
    translate,
    loading,
  };
}

export default withRouter(connect(mapStateToProps, null)(Profile));

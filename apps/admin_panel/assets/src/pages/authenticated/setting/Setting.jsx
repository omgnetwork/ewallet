import React, { Component } from 'react';
import { withRouter } from 'react-router-dom';
import { getTranslate } from 'react-localize-redux';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import { Button } from 'react-bootstrap';
import OMGFieldGroup from '../../../components/OMGFieldGroup';
import OMGPhotoPreviewer from '../../../components/OMGPhotoPreviewer';
import OMGAddMemberForm from '../../../components/OMGAddMemberForm';
import OMGMemberItem from '../../../components/OMGMemberItem';
import PlaceHolder from '../../../../public/images/user_icon_placeholder.png';

class Setting extends Component {
  constructor(props) {
    super(props);
    const { currentUser } = props;
    const {
      email, fullName, position, companyName, photoUrl, username,
    } = currentUser;
    this.state = {
      email,
      fullName,
      position,
      companyName,
      username,
      photoUrl: photoUrl || PlaceHolder,
      photoFile: null,
      valid: true,
    };
    this.handleFileChanged = this.handleFileChanged.bind(this);
    this.handleFormChanged = this.handleFormChanged.bind(this);
    this.handleCancel = this.handleCancel.bind(this);
    this.handleSave = this.handleSave.bind(this);
    this.validate = this.validate.bind(this);
  }

  // Invoke when the user clicks save button.
  handleSave() {
    // Just log the state for now.
    console.log(this.state);
  }

  // Invoke when the user clicks cancel button.
  handleCancel() {
    // Go to dashboard
    const { history } = this.props;
    history.push('/');
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

  // Invoke after handleFormChanged is called
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
            <OMGFieldGroup
              help=""
              id="username"
              label={translate('setting.form.account_name.label')}
              onChange={this.handleFormChanged}
              type="text"
              validationState={null}
              value={username}
            />
            <div className="mb-1 mt-3">
              <h4>
                {translate('setting.form.assign_team_member.label')}
              </h4>
            </div>
            <OMGAddMemberForm
              labelKey="label"
              roles={[
                { label: 'setting.form.roles.super_admin', value: 'super_admin' },
                { label: 'setting.form.roles.analyst', value: 'analyst' },
                { label: 'setting.form.roles.moderator', value: 'moderator' },
              ]}
            />
            <OMGMemberItem
              imageUrl="https://6f553f294d9c2b381dc8-21a51a0c688da9b8f39d1cd2f922214e.ssl.cf3.rackcdn.com/photos/131-3-4.jpg"
              name="Thibault Denizut"
              position="OmiseGO Software Developer Team Lead"
            />
            <OMGMemberItem
              imageUrl="https://6f553f294d9c2b381dc8-21a51a0c688da9b8f39d1cd2f922214e.ssl.cf3.rackcdn.com/photos/146-0-4.jpg"
              isPending
              name="Phuchit Sirimongkolsathien"
              position="OmiseGO Mobile App Developer"
            />
            <OMGMemberItem
              imageUrl="https://6f553f294d9c2b381dc8-21a51a0c688da9b8f39d1cd2f922214e.ssl.cf3.rackcdn.com/photos/139-0-4.jpg"
              name="Mederic Petit"
              position="OmiseGO Mobile App Developer"
            />
            <div className="mt-2">
              <Button
                bsClass="btn btn-omg-blue"
                bsStyle="primary"
                onClick={this.handleSave}
                type="button"
              >
                {translate('setting.form.save.label')}
              </Button>
              <Button
                bsClass="btn btn-omg-white"
                bsStyle="primary"
                className="ml-1"
                onClick={this.handleCancel}
                type="submit"
              >
                {translate('setting.form.cancel.label')}
              </Button>
            </div>
            <div className="mt-3">
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

Setting.defaultProps = {
  currentUser: {
    username: '',
    email: '',
    fullName: '',
    position: '',
    companyName: '',
    photoUrl: '',
  },
};

Setting.propTypes = {
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

export default withRouter(connect(mapStateToProps, null)(Setting));

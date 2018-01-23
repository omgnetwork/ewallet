import React, { Component } from 'react';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import { getTranslate } from 'react-localize-redux';
import { Button } from 'react-bootstrap';
import PropTypes from 'prop-types';
import Actions from './actions';
import AlertActions from '../../../../actions/alert.actions';
import OMGFieldGroup from '../../../../components/OMGFieldGroup';
import { accountURL } from '../../../../helpers/urlFormatter';

class NewUser extends Component {
  constructor(props) {
    super(props);
    this.state = {
      name: '',
      description: '',
      submitted: false,
      didModifyName: false,
    };

    this.handleChange = this.handleChange.bind(this);
    this.handleSubmit = this.handleSubmit.bind(this);
  }

  getNameValidationState() {
    const { submitted, didModifyName } = this.state;
    return !this.isNameValid() && (submitted || didModifyName) ? 'error' : null;
  }

  isNameValid() {
    const { name } = this.state;
    return name.length >= 4;
  }

  isFormValid() {
    return this.isNameValid();
  }

  handleChange(e) {
    const { id, value } = e.target;
    this.setState((prevState) => {
      let { didModifyName } = prevState;
      if (id === 'name') {
        didModifyName = true;
      }
      return {
        [id]: value,
        didModifyName,
      };
    });
  }

  handleSubmit(e) {
    e.preventDefault();
    this.setState({ submitted: true });
    const { name, description } = this.state;
    const {
      createUser, history, showSuccessAlert, translate, session,
    } = this.props;
    if (name) {
      createUser({ name, description }, (user) => {
        history.push(accountURL(session, '/users'));
        showSuccessAlert(translate('users.new.success', { name: user.name }));
      });
    }
  }

  render() {
    const { loading, translate } = this.props;
    const { name, description } = this.state;
    return (
      <div className="row">
        <div className="col-xs-12 col-sm-8">
          <div className="omg-form">
            <h2 className="omg-form__title">
              {translate('users.new.create_a_user')}
            </h2>
            <form autoComplete="off" onSubmit={this.handleSubmit}>
              <OMGFieldGroup
                help={translate('users.new.name.help')}
                id="name"
                label={translate('users.new.name.label')}
                onChange={this.handleChange}
                type="text"
                validationState={this.getNameValidationState()}
                value={name}
              />
              <OMGFieldGroup
                help={translate('users.new.description.help')}
                id="description"
                label={translate('users.new.description.label')}
                onChange={this.handleChange}
                type="text"
                validationState={null}
                value={description}
              />
              <Button
                bsClass="btn btn-omg-blue"
                bsStyle="primary"
                disabled={loading || !this.isFormValid()}
                type="submit"
              >
                {loading ? translate('global.loading') : translate('users.new.create')}
              </Button>
            </form>
          </div>
        </div>
      </div>
    );
  }
}

NewUser.propTypes = {
  createUser: PropTypes.func.isRequired,
  history: PropTypes.object.isRequired,
  loading: PropTypes.bool.isRequired,
  session: PropTypes.object.isRequired,
  showSuccessAlert: PropTypes.func.isRequired,
  translate: PropTypes.func.isRequired,
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
    showSuccessAlert: (message) => {
      dispatch(AlertActions.info(message));
    },
    createUser: (params, onSuccess) => dispatch(Actions.createUser(params, onSuccess)),
  };
}

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(NewUser));

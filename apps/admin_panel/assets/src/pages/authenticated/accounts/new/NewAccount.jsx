import React, { Component } from 'react';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import { getTranslate } from 'react-localize-redux';
import { Button } from 'react-bootstrap';
import PropTypes from 'prop-types';
import Actions from './actions';
import AlertActions from '../../../../actions/alert.actions';
import OMGFieldGroup from '../../../../components/OMGFieldGroup';

class NewAccount extends Component {
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
      createAccount, history, showSuccessAlert, translate,
    } = this.props;
    if (name) {
      createAccount({ name, description }, (account) => {
        history.push('/accounts');
        showSuccessAlert(translate('accounts.new.success', { name: account.name }));
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
              {translate('accounts.new.create_an_account')}
            </h2>
            <form autoComplete="off" onSubmit={this.handleSubmit}>
              <OMGFieldGroup
                help={translate('accounts.new.name.help')}
                id="name"
                label={translate('accounts.new.name.label')}
                onChange={this.handleChange}
                type="text"
                validationState={this.getNameValidationState()}
                value={name}
              />
              <OMGFieldGroup
                help={translate('accounts.new.description.help')}
                id="description"
                label={translate('accounts.new.description.label')}
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
                {loading ? translate('global.loading') : translate('accounts.new.create')}
              </Button>
            </form>
          </div>
        </div>
      </div>
    );
  }
}

NewAccount.propTypes = {
  createAccount: PropTypes.func.isRequired,
  history: PropTypes.object.isRequired,
  loading: PropTypes.bool.isRequired,
  showSuccessAlert: PropTypes.func.isRequired,
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

function mapDispatchToProps(dispatch) {
  return {
    showSuccessAlert: (message) => {
      dispatch(AlertActions.info(message));
    },
    createAccount: (params, onSuccess) => dispatch(Actions.createAccount(params, onSuccess)),
  };
}

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(NewAccount));

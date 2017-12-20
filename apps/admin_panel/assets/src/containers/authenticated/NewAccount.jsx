import React, { Component } from "react";
import { connect } from "react-redux";
import { withRouter } from "react-router-dom";
import { getTranslate } from 'react-localize-redux';
import { Button } from 'react-bootstrap';

import { accountActions } from "../../actions"
import { alertActions } from "../../actions"
import OMGFieldGroup from "../../components/OMGFieldGroup"

class NewAccount extends Component {

  constructor(props) {
    super(props);
    this.state = {
      name: "",
      description: "",
      submitted: false,
      didModifyName: false,
    };

    this.handleChange = this.handleChange.bind(this);
    this.handleSubmit = this.handleSubmit.bind(this);
  }

  handleChange(e) {
    const { id, value } = e.target;
    var { didModifyName} = this.state
    if (id === "name") { didModifyName = true }
    this.setState({ [id]: value,
                    didModifyName: didModifyName });
  }

  handleSubmit(e) {
    e.preventDefault();
    this.setState({ submitted: true });
    const { name, description } = this.state;
    const { createAccount, history, showSuccessAlert, translate } = this.props;
    if (name) {
      createAccount(name, description, (account) => {
        history.push("/accounts")
        showSuccessAlert(translate("accounts.new.success", { name: account.name }));
      });
    }
  }

  isNameValid() {
    return this.state.name.length >= 4
  }

  isFormValid() {
    return this.isNameValid()
  }

  getNameValidationState() {
    const { submitted, didModifyName } = this.state;
    return (!this.isNameValid() && (submitted || didModifyName)) ? "error" : null
  }

  render() {
    const { loading, translate } = this.props;
    const { name, description } = this.state
    return (
      <div className="row">
        <div className="col-xs-12 col-sm-8">
          <div className="omg-form">
            <h2 className="omg-form__title">{translate("accounts.new.create_an_account")}</h2>
            <form onSubmit={this.handleSubmit} autoComplete="off">
              <OMGFieldGroup
                id="name"
                label={translate("accounts.new.name.label")}
                help = {translate("accounts.new.name.help")}
                validationState={this.getNameValidationState()}
                type="text"
                value={name}
                onChange={this.handleChange}
              />
              <OMGFieldGroup
                id="description"
                label={translate("accounts.new.description.label")}
                help = {translate("accounts.new.description.help")}
                validationState={null}
                type="text"
                value={description}
                onChange={this.handleChange}
              />
              <Button bsClass="btn btn-omg-blue"
                      bsStyle="primary"
                      disabled={loading || !this.isFormValid()}
                      type="submit"
              >
                {loading ? translate("global.loading") : translate("accounts.new.create")}
              </Button>
            </form>
          </div>
        </div>
      </div>
    );
  }
}

function mapStateToProps(state) {
  const { loading } = state.global
  const translate = getTranslate(state.locale);
  return {
    translate, loading
  };
}

function mapDispatchToProps(dispatch) {
  return {
    showSuccessAlert: (message) => {
      dispatch(alertActions.info(message));
    },
    createAccount: (name, description, onSuccess) => {
      return dispatch(accountActions.createAccount(name, description, onSuccess))
    }
  };
}

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(NewAccount));

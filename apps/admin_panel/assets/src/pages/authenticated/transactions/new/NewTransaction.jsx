import React, { Component } from 'react';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import { getTranslate } from 'react-localize-redux';
import { Button } from 'react-bootstrap';
import PropTypes from 'prop-types';
import Actions from './actions';
import AlertActions from '../../../../actions/alert.actions';
import OMGFieldGroup from '../../../../components/OMGFieldGroup';

class NewTransaction extends Component {
  constructor(props) {
    super(props);
    this.state = {
      field1: '',
      field2: '',
      field3: '',
      field4: '',
    };
    this.handleSubmit = this.handleSubmit.bind(this);
    this.handleChange = this.handleChange.bind(this);
  }

  handleSubmit(e) {
    e.preventDefault();
    const {
      field1, field2, field3, field4,
    } = this.state;
    const {
      history, translate, createAccount, showSuccessAlert,
    } = this.props;

    createAccount(
      {
        field1,
        field2,
        field3,
        field4,
      },
      (transaction) => {
        history.push('/transactions');
        showSuccessAlert(translate('transactions.new.success', { transaction_id: transaction.id }));
      },
    );
  }

  handleChange(e) {
    const { id, value } = e.target;
    this.setState({
      [id]: value,
    });
  }

  render() {
    const { translate } = this.props;
    return (
      <div className="row">
        <div className="col-xs-12 col-sm-8">
          <div className="omg-form">
            <h1>
              {translate('transactions.new.create_a_transaction')}
            </h1>
            <form autoComplete="off">
              <OMGFieldGroup
                help=""
                id="field1"
                label={translate('transactions.new.field_1.label')}
                onChange={this.handleChange}
                type="text"
                validationState={null}
              />
              <OMGFieldGroup
                help=""
                id="field2"
                label={translate('transactions.new.field_2.label')}
                onChange={this.handleChange}
                type="text"
                validationState={null}
              />
              <OMGFieldGroup
                help=""
                id="field3"
                label={translate('transactions.new.field_3.label')}
                onChange={this.handleChange}
                type="text"
                validationState={null}
              />
              <OMGFieldGroup
                help=""
                id="field4"
                label={translate('transactions.new.field_4.label')}
                onChange={this.handleChange}
                type="text"
                validationState={null}
              />
              <Button
                bsClass="btn btn-omg-blue"
                bsStyle="primary"
                onClick={this.handleSubmit}
                type="submit"
              >
                Create
              </Button>
            </form>
          </div>
        </div>
      </div>
    );
  }
}

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
    createAccount: (params, onSuccess) => dispatch(Actions.createAccount(params, onSuccess)),
    showSuccessAlert: (message) => {
      dispatch(AlertActions.info(message));
    },
  };
}

NewTransaction.propTypes = {
  createAccount: PropTypes.func.isRequired,
  history: PropTypes.object.isRequired,
  showSuccessAlert: PropTypes.func.isRequired,
  translate: PropTypes.func.isRequired,
};

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(NewTransaction));

import React, { Component } from 'react';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import { getTranslate } from 'react-localize-redux';
import { Button, Checkbox } from 'react-bootstrap';
import PropTypes from 'prop-types';
import Actions from './actions';
import allFields from './fields';
import AlertActions from '../../../../actions/alert.actions';
import OMGFieldGroup from '../../../../components/OMGFieldGroup';
import { accountURL } from '../../../../helpers/urlFormatter';

class NewToken extends Component {
  constructor(props) {
    super(props);
    this.state = {
      symbol: '',
      isoCode: '',
      name: '',
      description: '',
      shortSymbol: '',
      subUnit: '',
      subUnitToUnit: '',
      symbolFirst: true,
      htmlEntity: '',
      isoNumeric: '',
      smallestDenomination: '',
      locked: false,
    };
    this.handleSubmit = this.handleSubmit.bind(this);
    this.handleChange = this.handleChange.bind(this);
    this.handleCheckChange = this.handleCheckChange.bind(this);
  }

  handleSubmit(e) {
    e.preventDefault();
    const {
      symbol,
      isoCode,
      name,
      description,
      shortSymbol,
      subUnit,
      subUnitToUnit,
      symbolFirst,
      htmlEntity,
      isoNumeric,
      smallestDenomination,
      locked,
    } = this.state;

    const {
      history, translate, createToken, showSuccessAlert, session,
    } = this.props;

    createToken(
      {
        symbol,
        isoCode,
        name,
        description,
        shortSymbol,
        subUnit,
        subUnitToUnit,
        symbolFirst,
        htmlEntity,
        isoNumeric,
        smallestDenomination,
        locked,
      },
      (token) => {
        history.push(accountURL(session, '/tokens'));
        showSuccessAlert(translate('tokens.new.success', { token_id: token.id }));
      },
    );
  }

  handleChange(e) {
    const { id, value } = e.target;
    this.setState({
      [id]: value,
    });
  }

  handleCheckChange(e) {
    const { id, checked } = e.target;
    this.setState({
      [id]: checked,
    });
  }

  render() {
    const { translate } = this.props;
    const { symbolFirst, locked } = this.state;

    const fields = allFields.map((v, index) => {
      const translated = translate(v.translateId);
      const checkBox = {
        checked: v.name === 'locked' ? locked : symbolFirst,
        id: v.name === 'locked' ? 'locked' : 'symbolFirst',
      };
      switch (v.type) {
        case 'boolean':
          return (
            <Checkbox
              key={index}
              checked={checkBox.checked}
              className="omg-form__group"
              id={checkBox.id}
              onChange={this.handleCheckChange}
            >
              <div className="omg-form__label">
                {translated}
              </div>
            </Checkbox>
          );
        default:
          return (
            <OMGFieldGroup
              key={v.name}
              help=""
              id={v.name}
              label={translate(v.translateId)}
              onChange={this.handleChange}
              type="text"
              validationState={null}
            />
          );
      }
    });

    return (
      <div className="row">
        <div className="col-xs-12 col-sm-8">
          <div className="omg-form">
            <h1>
              {translate('tokens.new.create_a_token')}
            </h1>
            <form autoComplete="off">
              {fields}
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
  const { session } = state;
  return {
    translate,
    loading,
    session,
  };
}

function mapDispatchToProps(dispatch) {
  return {
    createToken: (params, onSuccess) => dispatch(Actions.createToken(params, onSuccess)),
    showSuccessAlert: (message) => {
      dispatch(AlertActions.info(message));
    },
  };
}

NewToken.propTypes = {
  createToken: PropTypes.func.isRequired,
  history: PropTypes.object.isRequired,
  session: PropTypes.object.isRequired,
  showSuccessAlert: PropTypes.func.isRequired,
  translate: PropTypes.func.isRequired,
};

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(NewToken));

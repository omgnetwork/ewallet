import React, { Component } from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import { getTranslate } from 'react-localize-redux';
import AlertActions from '../../../../actions/alert.actions';
import { deleteApiKey, loadApiKeys } from './actions';
import tables from './tables';
import headerText from './header';
import { processURL, accountURL, formatURL } from '../../../../helpers/urlFormatter';
import OMGCompleteTable from '../../../../components/OMGCompleteTable';

class APIManagement extends Component {
  constructor(props) {
    super(props);
    this.handleDeleteApiKeySuccess = this.handleDeleteApiKeySuccess.bind(this);
  }

  handleDeleteApiKeySuccess() {
    const {
      history, session,
    } = this.props;

    const newURL = {
      ...processURL(history.location),
      update: Date.now(),
    };
    history.push(formatURL(accountURL(session, '/api_management'), newURL));
  }

  render() {
    const handleCallback = {
      onSuccess: (this.handleDeleteApiKeySuccess),
    };

    return (
      <OMGCompleteTable
        createRecordUrl="/api_management/new"
        handleCallback={handleCallback}
        headerText={headerText}
        tables={tables}
        {...this.props}
      />
    );
  }
}

APIManagement.propTypes = {
  history: PropTypes.object.isRequired,
  session: PropTypes.object.isRequired,
  showSuccessAlert: PropTypes.func.isRequired,
  translate: PropTypes.func.isRequired,
};

const mapStateToProps = (state) => {
  const { session } = state;
  const translate = getTranslate(state.locale);
  return {
    session,
    translate,
  };
};

const mapDispatchToProps = dispatch => ({
  handleActions: {
    delete: (id, onSuccess) => dispatch(deleteApiKey({ id }, onSuccess)),
  },
  loadData: (query, onSuccess) => dispatch(loadApiKeys(query, onSuccess)),
  showSuccessAlert: message => dispatch(AlertActions.success(message)),
});

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(APIManagement));

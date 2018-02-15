import React from 'react';
import { connect } from 'react-redux';
import { viewAs, loadAccounts } from './actions';
import OMGCompleteTable from '../../../../components/OMGCompleteTable';
import tables from './tables';
import headerText from './header';

const Accounts = props => (
  <OMGCompleteTable
    createRecordUrl="/accounts/new"
    headerText={headerText}
    tables={tables}
    {...props}
  />
);

function mapDispatchToProps(dispatch) {
  return {
    handleActions: {
      viewAs: accountId => dispatch(viewAs(accountId)),
    },
    loadData: (query, onSuccess) => dispatch(loadAccounts(query, onSuccess)),
  };
}

export default connect(null, mapDispatchToProps)(Accounts);

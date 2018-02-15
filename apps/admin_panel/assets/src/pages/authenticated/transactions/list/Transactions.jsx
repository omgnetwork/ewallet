import React from 'react';
import { connect } from 'react-redux';
import Actions from './actions';
import tables from './tables';
import headerText from './header';
import OMGCompleteTable from '../../../../components/OMGCompleteTable';

const Transactions = props => (
  <OMGCompleteTable
    createRecordUrl="/transactions/new"
    headerText={headerText}
    tables={tables}
    {...props}
  />
);


const mapDispatchToProps = dispatch => ({
  loadData: (query, onSuccess) => dispatch(Actions.loadTransactions(query, onSuccess)),
});

export default connect(null, mapDispatchToProps)(Transactions);

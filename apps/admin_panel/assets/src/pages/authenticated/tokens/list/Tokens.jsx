import React from 'react';
import { connect } from 'react-redux';
import tables from './tables';
import headerText from './header';
import OMGCompleteTable from '../../../../components/OMGCompleteTable';
import Actions from './actions';

const Tokens = props => (
  <OMGCompleteTable
    createRecordUrl="/tokens/new"
    headerText={headerText}
    tables={tables}
    {...props}
  />
);

const mapDispatchToProps = dispatch => ({
  loadData: (query, onSuccess) => dispatch(Actions.loadTokens(query, onSuccess)),
});

export default connect(null, mapDispatchToProps)(Tokens);

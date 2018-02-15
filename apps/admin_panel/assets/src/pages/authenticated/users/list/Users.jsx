import React from 'react';
import { connect } from 'react-redux';
import Actions from './actions';
import tables from './tables';
import headerText from './header';
import OMGCompleteTable from '../../../../components/OMGCompleteTable';

const Users = props => (
  <OMGCompleteTable
    createRecordUrl="/users/new"
    headerText={headerText}
    tables={tables}
    {...props}
  />
);

const mapDispatchToProps = dispatch => ({
  loadData: (query, onSuccess) => dispatch(Actions.loadUsers(query, onSuccess)),
});

export default connect(null, mapDispatchToProps)(Users);

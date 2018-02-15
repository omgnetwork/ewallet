import React from 'react';
import { connect } from 'react-redux';
import OMGCompleteTable from '../../../../components/OMGCompleteTable';
import loadAdmins from './actions';
import tables from './tables';
import headerText from './header';

const Admins = props => (
  <OMGCompleteTable
    headerText={headerText}
    tables={tables}
    visible={{ addBtn: false }}
    {...props}
  />
);

const mapDispatchToProps = dispatch => ({
  loadData: (query, onSuccess) => dispatch(loadAdmins(query, onSuccess)),
});

export default connect(null, mapDispatchToProps)(Admins);

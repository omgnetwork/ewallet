import React from 'react';
import { Table } from 'react-bootstrap';
import { localize } from 'react-localize-redux';
import PropTypes from 'prop-types';
import AccountRow from './AccountRow';

const AccountsTable = ({ accounts, translate }) => {
  const accountRows = accounts.map(account => <AccountRow account={account} key={account.id} />);
  return (
    <Table responsive>
      <thead>
        <tr>
          <th>{translate('accounts.table.id')}</th>
          <th>{translate('accounts.table.name')}</th>
          <th>{translate('accounts.table.master')}</th>
          <th>{translate('accounts.table.description')}</th>
        </tr>
      </thead>
      <tbody>{accountRows}</tbody>
    </Table>
  );
};

AccountsTable.defaultProps = {
  accounts: [],
};

AccountsTable.propTypes = {
  accounts: PropTypes.arrayOf(PropTypes.shape({
    id: PropTypes.string.isRequired,
    name: PropTypes.string.isRequired,
    master: false,
    description: PropTypes.string,
  })),
  translate: PropTypes.func.isRequired,
};

export default localize(AccountsTable, 'locale');

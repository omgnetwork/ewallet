import React, { Component } from "react";
import { Table } from 'react-bootstrap';
import { localize } from 'react-localize-redux';

import AccountRow from "./AccountRow"

class AccountsTable extends Component {

  render() {
    const { accounts, translate } = this.props
    const accountRows = accounts.map(account =>
      <AccountRow account={account} key={account.id} />
    )
    return(
      <Table responsive>
        <thead>
          <tr>
            <th>{translate("accounts.table.id")}</th>
            <th>{translate("accounts.table.name")}</th>
            <th>{translate("accounts.table.master")}</th>
            <th>{translate("accounts.table.description")}</th>
          </tr>
        </thead>
        <tbody>
          {accountRows}
        </tbody>
      </Table>
    );
  }

}

export default localize(AccountsTable, 'locale');

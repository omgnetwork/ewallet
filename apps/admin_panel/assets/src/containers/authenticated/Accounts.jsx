import React, { Component } from "react";
import { connect } from "react-redux";
import { withRouter } from "react-router-dom";
import { Table } from 'react-bootstrap';
import { getTranslate } from 'react-localize-redux';

import { accountActions } from "../../actions";

class Accounts extends Component {

  componentDidMount() {
    const { getAll } = this.props;
    getAll();
  }

  constructor(props) {
    super(props);
  }

  render() {
    const { requesting, accounts, translate } = this.props;
    const acc = accounts.map(account =>
      <tr key={account.id}>
          <td>{account.id}</td>
          <td>{account.name}</td>
          <td>{account.master ? "true" : "false"}</td>
          <td>{account.description}</td>
      </tr>
    )
    return(
      <div>
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
            {acc}
          </tbody>
        </Table>
      </div>
    );
  }

}

function mapStateToProps(state) {
  const { requesting, accounts } = state.account;
  const translate = getTranslate(state.locale);
  return {
    requesting, accounts, translate
  };
}

function mapDispatchToProps(dispatch) {
  return {
    getAll: () => {
      return dispatch(accountActions.getAll())
    }
  };
}

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(Accounts));

import React, { Component } from "react";
import { connect } from "react-redux";
import { withRouter } from "react-router-dom";
import { Table } from 'react-bootstrap';
import { getTranslate } from 'react-localize-redux';
import { push } from "react-router-redux";

import AccountRow from "../../components/authenticated/AccountRow"
import AccountsHeader from "./AccountsHeader"
import { urlFormatter } from "../../helpers"
import { accountActions } from "../../actions"

class Accounts extends Component {

  componentDidMount() {
    this.processURLParams(this.props.location);
  }

  componentWillReceiveProps(nextProps) {
    const { location } = nextProps
    if (location !== this.props.location) {
      this.processURLParams(location);
    }
  }

  constructor(props) {
    super(props);
    this.state = { accounts: [], query:"" }
    this.updateURLQuery = this.updateURLQuery.bind(this)
  }

  render() {
    const { loading, translate } = this.props;
    const { accounts, query } = this.state
    const acc = accounts.map(account =>
      <AccountRow account={account} key={account.id} />
    )
    return (
      <div>
        <AccountsHeader
          query={query}
          handleSubmit={this.updateURLQuery}
        />
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

  loadAccounts() {
    const { loadAccounts } = this.props
    const { query } = this.state
    loadAccounts(query, (accounts) => {
      this.setState({accounts})
    });
  }

  updateURLQuery(query) {
    const { pushURL } = this.props
    pushURL(urlFormatter.formatURL("/accounts", {"q":query}))
  }

  processURLParams(location) {
    const params = urlFormatter.processURL(location)
    const query = params.q ? params.q : ""
    this.setState({query})
    this.loadAccounts()
  }
}

function mapStateToProps(state) {
  const { loading } = state.global
  const translate = getTranslate(state.locale);
  return {
    translate, loading
  };
}

function mapDispatchToProps(dispatch) {
  return {
    pushURL: (path) => {
      return dispatch(push(path))
    },
    loadAccounts: (query, onSuccess) => {
      return dispatch(accountActions.loadAccounts(query, onSuccess))
    }
  };
}

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(Accounts));

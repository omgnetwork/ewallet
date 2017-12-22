import React, { Component } from "react";
import { connect } from "react-redux";
import { withRouter } from "react-router-dom";
import { getTranslate } from 'react-localize-redux';

import AccountsHeader from "../../../components/authenticated/AccountsHeader"
import AccountsTable from "../../../components/authenticated/AccountsTable"
import OMGPager from "../../../components/OMGPager"
import { urlFormatter } from "../../../helpers"
import { accountActions } from "../../../actions"
import { PAGINATION } from "../../../helpers/constants"

class Accounts extends Component {

  componentDidMount() {
    this.processURLParams(this.props.location)
  }

  componentWillReceiveProps(nextProps) {
    const newLocation = nextProps.location
    const oldLocationSearch = this.props.location.search
    if (newLocation.search !== oldLocationSearch) {
      this.processURLParams(newLocation);
    }
  }

  constructor(props) {
    super(props);
    this.state = { accounts: [],
                   query:"",
                   currentPage: PAGINATION.PAGE,
                   per: PAGINATION.PER,
                   isLastPage: true,
                   isFirstPage: true }
    this.onSearchChange = this.onSearchChange.bind(this)
    this.onPageChange = this.onPageChange.bind(this)
    this.onNewAccount = this.onNewAccount.bind(this)
  }

  render() {
    const { loading } = this.props;
    const { accounts, query, isFirstPage, isLastPage, currentPage } = this.state
    return (
      <div>
        <AccountsHeader query={query}
                        onSearchChange={this.onSearchChange}
                        onNewAccount={this.onNewAccount} />
        <AccountsTable accounts={accounts} />
        <OMGPager isFirstPage={isFirstPage}
                  isLastPage={isLastPage}
                  currentPage={currentPage}
                  onPageChange={this.onPageChange} />
      </div>
    );
  }

  updateURL() {
    const { push } = this.props.history
    const { currentPage, per, query } = this.state
    push(urlFormatter.formatURL("/accounts", {"page":currentPage, "per": per, "q": query}))
  }

  processURLParams(location) {
    const { loadAccounts } = this.props
    const params = urlFormatter.processURL(location)
    const query = params.q ? params.q : ""
    const currentPage = params.page ? parseInt(params.page) : PAGINATION.PAGE
    const per = params.per ? Math.min(parseInt(params.per), PAGINATION.PER) : PAGINATION.PER
    this.setState({query, currentPage, per})
    loadAccounts(query, currentPage, per, (accounts, pagination) => {
      this.setState({ accounts,
                      isFirstPage:pagination.isFirstPage,
                      isLastPage:pagination.isLastPage })
    });
  }

  onNewAccount() {
    const { push } = this.props.history
    push("/accounts/new")
  }

  onPageChange(newPage) {
    this.setState({currentPage: newPage}, this.updateURL)
  }

  onSearchChange(query) {
    this.setState({ query,
                    currentPage:PAGINATION.PAGE,
                    per:PAGINATION.PER,
                    isLastPage: true,
                    isFirstPage: true },
                    this.updateURL)
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
    loadAccounts: (query, page, per, onSuccess) => {
      return dispatch(accountActions.loadAccounts(query, page, per, onSuccess))
    }
  };
}

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(Accounts));

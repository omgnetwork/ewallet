import React, { Component } from 'react';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import { getTranslate } from 'react-localize-redux';
import PropTypes from 'prop-types';
import AccountsHeader from './AccountsHeader';
import AccountsTable from './AccountsTable';
import OMGPager from '../../../../components/OMGPager';
import Actions from './actions';
import { PAGINATION } from '../../../../helpers/constants';

class Accounts extends Component {
  constructor(props) {
    super(props);
    this.state = {
      accounts: [],
      query: '',
      currentPage: PAGINATION.PAGE,
      per: PAGINATION.PER,
      isLastPage: true,
      isFirstPage: true,
    };
    this.onSearchChange = this.onSearchChange.bind(this);
    this.onPageChange = this.onPageChange.bind(this);
    this.onNewAccount = this.onNewAccount.bind(this);
    this.onURLChanged = this.onURLChanged.bind(this);
  }

  componentDidMount() {
    Actions.processURLParams(this.props.location, this.onURLChanged);
  }

  componentWillReceiveProps(nextProps) {
    const newLocation = nextProps.location;
    const oldLocationSearch = this.props.location.search;
    if (newLocation.search !== oldLocationSearch) {
      Actions.processURLParams(newLocation, this.onURLChanged);
    }
  }

  onNewAccount() {
    Actions.updateURL(this.props.history.push, '/accounts/new');
  }

  onPageChange(newPage) {
    this.setState(
      {
        currentPage: newPage,
      },
      this.updateURL,
    );
  }

  onSearchChange(query) {
    this.setState(
      {
        query,
        currentPage: PAGINATION.PAGE,
        per: PAGINATION.PER,
        isLastPage: true,
        isFirstPage: true,
      },
      this.updateURL,
    );
  }

  onURLChanged(page) {
    this.setState(page);
    this.props.loadAccounts(page, (accounts, pagination) => {
      this.setState({
        accounts,
        isFirstPage: pagination.isFirstPage,
        isLastPage: pagination.isLastPage,
      });
    });
  }

  updateURL() {
    const { push } = this.props.history;
    const { currentPage, per, query } = this.state;
    const params = {
      page: currentPage,
      per,
      q: query,
    };
    Actions.updateURL(push, '/accounts', params);
  }

  render() {
    // const { loading } = this.props;
    const {
      accounts, query, isFirstPage, isLastPage, currentPage,
    } = this.state;

    return (
      <div>
        <AccountsHeader
          query={query}
          onSearchChange={this.onSearchChange}
          onNewAccount={this.onNewAccount}
        />
        <AccountsTable accounts={accounts.data} />
        <OMGPager
          isFirstPage={isFirstPage}
          isLastPage={isLastPage}
          currentPage={currentPage}
          onPageChange={this.onPageChange}
        />
      </div>
    );
  }
}

Accounts.propTypes = {
  location: PropTypes.object.isRequired, // eslint-disable-line react/forbid-prop-types
  history: PropTypes.object.isRequired, // eslint-disable-line react/forbid-prop-types
  loadAccounts: PropTypes.func.isRequired,
};

function mapStateToProps(state) {
  const { loading } = state.global;
  const translate = getTranslate(state.locale);
  return { translate, loading };
}

function mapDispatchToProps(dispatch) {
  return {
    loadAccounts: (query, onSuccess) => dispatch(Actions.loadAccounts(query, onSuccess)),
  };
}

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(Accounts));

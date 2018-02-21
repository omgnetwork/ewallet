import React from 'react';
import { connect } from 'react-redux';
import { Switch, Redirect, withRouter } from 'react-router-dom';
import PropTypes from 'prop-types';

import AuthenticatedRoute from '../authenticated/AuthenticatedRoute';
import Home from '../authenticated/home/Home';
import Accounts from '../authenticated/accounts/list/Accounts';
import NewAccount from '../authenticated/accounts/new/NewAccount';
import Users from '../authenticated/users/list/Users';
import NewUser from '../authenticated/users/new/NewUser';
import APIManagement from '../authenticated/api_management/list/APIManagement';
import NewAPI from '../authenticated/api_management/new/NewAPI';
import Report from '../authenticated/report/Report';
import Transactions from '../authenticated/transactions/list/Transactions';
import NewTransaction from '../authenticated/transactions/new/NewTransaction';
import Setting from '../authenticated/setting/Setting';
import Tokens from '../authenticated/tokens/list/Tokens';
import NewToken from '../authenticated/tokens/new/NewToken';
import Admins from '../authenticated/admins/list/Admins';
import Profile from '../authenticated/profile/Profile';

const AccountRouter =
({
  computedMatch, session, history,
}) => {
  const { currentAccount } = session;
  if (!currentAccount) { return (<Redirect to={{ pathname: '/signin' }} />); }
  const accountId = computedMatch.params.id;
  const accountPath = `/a/${currentAccount.id}`;
  if (!accountId) {
    return (<Redirect to={{ pathname: `${accountPath}${history.location.pathname}`, search: history.location.search }} />);
  } else if (accountId !== currentAccount.id) {
    const updatedPath = history.location.pathname.replace(/\/a\/.*(?=\/)/, accountPath);
    return (<Redirect to={{ pathname: updatedPath, search: history.location.search }} />);
  }
  return (
    <Switch>
      <AuthenticatedRoute component={Home} exact path={`${accountPath}/`} />
      <AuthenticatedRoute component={Accounts} exact path={`${accountPath}/accounts`} />
      <AuthenticatedRoute component={NewAccount} exact path={`${accountPath}/accounts/new`} />
      <AuthenticatedRoute component={APIManagement} exact path={`${accountPath}/api_management`} />
      <AuthenticatedRoute component={NewAPI} exact path={`${accountPath}/api_management/new`} />
      <AuthenticatedRoute component={Report} exact path={`${accountPath}/report`} />
      <AuthenticatedRoute component={Transactions} exact path={`${accountPath}/transactions`} />
      <AuthenticatedRoute component={NewTransaction} exact path={`${accountPath}/transactions/new`} />
      <AuthenticatedRoute component={Users} exact path={`${accountPath}/users`} />
      <AuthenticatedRoute component={NewUser} exact path={`${accountPath}/users/new`} />
      <AuthenticatedRoute component={Tokens} exact path={`${accountPath}/tokens`} />
      <AuthenticatedRoute component={NewToken} exact path={`${accountPath}/tokens/new`} />
      <AuthenticatedRoute component={Setting} exact path={`${accountPath}/setting`} />
      <AuthenticatedRoute component={Admins} exact path={`${accountPath}/admins`} />
      <AuthenticatedRoute component={Profile} exact path={`${accountPath}/profile`} />
    </Switch>
  );
};

AccountRouter.propTypes = {
  computedMatch: PropTypes.object.isRequired,
  history: PropTypes.object.isRequired,
  session: PropTypes.object.isRequired,
};

function mapStateToProps(state) {
  const { session } = state;
  return { session };
}

export default withRouter(connect(mapStateToProps)(AccountRouter));

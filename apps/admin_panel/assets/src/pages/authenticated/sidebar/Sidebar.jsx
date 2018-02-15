import React from 'react';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import { getTranslate } from 'react-localize-redux';
import { Image } from 'react-bootstrap';
import PropTypes from 'prop-types';
import SidebarLink from './SidebarLink';

import logo from '../../../../public/images/user_icon_placeholder.png';

const Sidebar = ({ translate, history, session }) => {
  const accountPath = `/a/${session.currentAccount.id}`;
  return (
    <div className="sidebar fh">
      <div className="sidebar__content">
        <div className="col-xs-10 col-xs-offset-1">
          <Image className="sidebar__logo" src={session.currentAccount.avatar.large || logo} />
          <h2 className="sidebar__title">
            {session.currentAccount.name}
          </h2>
          <ul className="sidebar__ul">
            <li className="sidebar__li">
              <SidebarLink
                currentPath={history.location.pathname}
                title={translate('sidebar.dashboard')}
                to={`${accountPath}`}
              />
            </li>
            <li className="sidebar__li">
              <SidebarLink
                currentPath={history.location.pathname}
                title={translate('sidebar.accounts')}
                to={`${accountPath}/accounts`}
              />
            </li>
            <li className="sidebar__li">
              <SidebarLink
                currentPath={history.location.pathname}
                title={translate('sidebar.admins')}
                to={`${accountPath}/admins`}
              />
            </li>
            <li className="sidebar__li">
              <SidebarLink
                currentPath={history.location.pathname}
                title={translate('sidebar.users')}
                to={`${accountPath}/users`}
              />
            </li>
            <li className="sidebar__li">
              <SidebarLink
                currentPath={history.location.pathname}
                title={translate('sidebar.transactions')}
                to={`${accountPath}/transactions`}
              />
            </li>
            <li className="sidebar__li">
              <SidebarLink
                currentPath={history.location.pathname}
                title={translate('sidebar.tokens')}
                to={`${accountPath}/tokens`}
              />
            </li>
            <li className="sidebar__li sidebar__disabled">
              {`${translate('sidebar.reports')} (${translate('global.coming_soon')})`}
            </li>
            <li className="sidebar__li">
              <SidebarLink
                currentPath={history.location.pathname}
                title={translate('sidebar.api_management')}
                to={`${accountPath}/api_management`}
              />
            </li>
            <li className="sidebar__li">
              <SidebarLink
                currentPath={history.location.pathname}
                title={translate('sidebar.account_setting')}
                to={`${accountPath}/setting`}
              />
            </li>
          </ul>
        </div>
      </div>
    </div>
  );
};

Sidebar.propTypes = {
  history: PropTypes.object.isRequired,
  session: PropTypes.object.isRequired,
  translate: PropTypes.func.isRequired,
};

function mapStateToProps(state) {
  const translate = getTranslate(state.locale);
  const { session } = state;
  return {
    translate,
    session,
  };
}

export default withRouter(connect(mapStateToProps)(Sidebar));

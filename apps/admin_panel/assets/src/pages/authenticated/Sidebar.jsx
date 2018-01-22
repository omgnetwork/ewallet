import React from 'react';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import { getTranslate } from 'react-localize-redux';
import { Image } from 'react-bootstrap';
import PropTypes from 'prop-types';
import SidebarLink from './SidebarLink';

import logo from '../../../public/images/dummy_sidebar_logo.png';

const Sidebar = ({ translate, currentPath, session }) => {
  const accountPath = `/a/${session.currentAccount.id}`;
  return (
    <div className="sidebar fh">
      <div className="col-xs-10 col-xs-offset-1">
        <Image className="sidebar__logo" src={logo} />
        <h2 className="sidebar__title">
          Minor International
        </h2>
        <ul className="sidebar__ul">
          <li className="sidebar__li">
            <SidebarLink
              currentPath={currentPath}
              title={translate('sidebar.dashboard')}
              to={`${accountPath}/`}
            />
          </li>
          <li className="sidebar__li">
            <SidebarLink
              currentPath={currentPath}
              title={translate('sidebar.accounts')}
              to={`${accountPath}/accounts`}
            />
          </li>
          <li className="sidebar__li">
            <SidebarLink
              currentPath={currentPath}
              title={translate('sidebar.admins')}
              to={`${accountPath}/admins`}
            />
          </li>
          <li className="sidebar__li">
            <SidebarLink
              currentPath={currentPath}
              title={translate('sidebar.users')}
              to={`${accountPath}/users`}
            />
          </li>
          <li className="sidebar__li">
            <SidebarLink
              currentPath={currentPath}
              title={translate('sidebar.transactions')}
              to={`${accountPath}/transactions`}
            />
          </li>
          <li className="sidebar__li">
            <SidebarLink
              currentPath={currentPath}
              title={translate('sidebar.tokens')}
              to={`${accountPath}/tokens`}
            />
          </li>
          <li className="sidebar__li">
            <SidebarLink
              currentPath={currentPath}
              title={translate('sidebar.reports')}
              to={`${accountPath}/report`}
            />
          </li>
          <li className="sidebar__li">
            <SidebarLink
              currentPath={currentPath}
              title={translate('sidebar.api_management')}
              to={`${accountPath}/api_management`}
            />
          </li>
          <li className="sidebar__li">
            <SidebarLink
              currentPath={currentPath}
              title={translate('sidebar.setting')}
              to={`${accountPath}/setting`}
            />
          </li>
        </ul>
      </div>
    </div>
  );
};

Sidebar.propTypes = {
  currentPath: PropTypes.string.isRequired,
  session: PropTypes.object.isRequired,
  translate: PropTypes.func.isRequired,
};

function mapStateToProps(state) {
  const translate = getTranslate(state.locale);
  const currentPath = state.router.location.pathname;
  const { session } = state;
  return {
    translate,
    currentPath,
    session,
  };
}

export default withRouter(connect(mapStateToProps)(Sidebar));

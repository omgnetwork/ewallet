import React from 'react';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import { getTranslate } from 'react-localize-redux';
import { Image } from 'react-bootstrap';
import PropTypes from 'prop-types';
import SidebarLink from './SidebarLink';

import logo from '../../../public/images/dummy_sidebar_logo.png';

const Sidebar = ({ translate, currentPath }) => (
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
            to="/"
          />
        </li>
        <li className="sidebar__li">
          <SidebarLink
            currentPath={currentPath}
            title={translate('sidebar.accounts')}
            to="/accounts"
          />
        </li>
        <li className="sidebar__li">
          <SidebarLink
            currentPath={currentPath}
            title={translate('sidebar.users')}
            to="/users"
          />
        </li>
        <li className="sidebar__li">
          <SidebarLink
            currentPath={currentPath}
            title={translate('sidebar.transactions')}
            to="/transactions"
          />
        </li>
        <li className="sidebar__li">
          <SidebarLink
            currentPath={currentPath}
            title={translate('sidebar.tokens')}
            to="/tokens"
          />
        </li>
        <li className="sidebar__li">
          <SidebarLink
            currentPath={currentPath}
            title={translate('sidebar.reports')}
            to="/report"
          />
        </li>
        <li className="sidebar__li">
          <SidebarLink
            currentPath={currentPath}
            title={translate('sidebar.api_management')}
            to="/api_management"
          />
        </li>
        <li className="sidebar__li">
          <SidebarLink
            currentPath={currentPath}
            title={translate('sidebar.setting')}
            to="/setting"
          />
        </li>
      </ul>
    </div>
  </div>
);

Sidebar.propTypes = {
  currentPath: PropTypes.string.isRequired,
  translate: PropTypes.func.isRequired,
};

function mapStateToProps(state) {
  const translate = getTranslate(state.locale);
  const currentPath = state.router.location.pathname;
  return {
    translate,
    currentPath,
  };
}

export default withRouter(connect(mapStateToProps)(Sidebar));

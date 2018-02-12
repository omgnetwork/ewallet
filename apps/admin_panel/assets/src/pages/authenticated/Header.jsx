import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import { getTranslate } from 'react-localize-redux';
import { Image, Navbar, Nav, NavItem, NavDropdown, MenuItem } from 'react-bootstrap';

import Actions from './actions';
import logo from '../../../public/images/omisego_logo_white.png';
import defaultAvatar from '../../../public/images/user_icon_placeholder.png';

const Header = ({
  session, history, logout, translate,
}) => {
  const accountPath = `/a/${session.currentAccount.id}`;
  const { currentUser } = session;
  return (
    <div>
      <div>
        <div className="header">
          <Navbar className="header header__navbar" collapseOnSelect fixedTop staticTop>
            <div className="col-md-3 col-xs-12 col-sm-4">
              <Navbar.Header className="col-md-10 col-md-offset-1 col-xs-12 col-sm-12 header__left">
                <Navbar.Brand>
                  <Image className="header__logo" onClick={() => { history.push(`${accountPath}/`); }} src={logo} />
                </Navbar.Brand>
                <Navbar.Toggle />
              </Navbar.Header>
            </div>
            <div className="col-md-9 col-sm-8 col-xs-12 header__right">
              <Navbar.Collapse>
                <Nav className="omg-hide">
                  <NavDropdown
                    className="omg-dropdown"
                    eventKey={1}
                    id="omg-nav-dropdown"
                    title="Select Accounts"
                  >
                    <MenuItem eventKey={1.2}>
                      Account 1
                    </MenuItem>
                    <MenuItem eventKey={1.3}>
                      Account 2
                    </MenuItem>
                    <MenuItem eventKey={1.3}>
                      Account 3
                    </MenuItem>
                  </NavDropdown>
                </Nav>
                <Nav className="omg-nav" pullRight>
                  <NavItem className="omg-nav__avatar" eventKey={3} href="#" id="avatar">
                    <Image circle src={currentUser.avatar.small || defaultAvatar} />
                  </NavItem>
                  <NavDropdown
                    className="omg-dropdown__gray"
                    eventKey={4}
                    id={4}
                    title={session.currentUser.email}
                  >
                    <MenuItem
                      eventKey={4.1}
                      onClick={() => {
                        history.push(`${accountPath}/profile`);
                      }}
                    >
                      {translate('header.edit_profile')}
                    </MenuItem>
                    <MenuItem
                      eventKey={4.2}
                      onClick={() => {
                        logout();
                      }}
                    >
                      Log Out
                    </MenuItem>
                  </NavDropdown>
                </Nav>
              </Navbar.Collapse>
            </div>
          </Navbar>
        </div>
      </div>
    </div>
  );
};

function mapDispatchToProps(dispatch) {
  return {
    logout: () => dispatch(Actions.logout()),
  };
}

function mapStateToProps(state) {
  const { session } = state;
  const translate = getTranslate(state.locale);
  return {
    session,
    translate,
  };
}

Header.propTypes = {
  history: PropTypes.object.isRequired,
  logout: PropTypes.func.isRequired,
  session: PropTypes.object.isRequired,
  translate: PropTypes.func.isRequired,
};

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(Header));

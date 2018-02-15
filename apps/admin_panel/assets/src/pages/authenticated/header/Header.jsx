import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import { getTranslate } from 'react-localize-redux';
import { Image, Navbar } from 'react-bootstrap';
import logo from '../../../../public/images/omisego_logo_white.png';
import UserInfoNavItem from './UserInfoNavItem';

const Header = ({
  session, history,
}) => {
  const accountPath = `/a/${session.currentAccount.id}`;
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
              <Navbar.Collapse className="omg-navbar-collapse">
                <UserInfoNavItem accountPath={accountPath} />
              </Navbar.Collapse>
            </div>
          </Navbar>
        </div>
      </div>
    </div>
  );
};

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
  session: PropTypes.object.isRequired,
};

export default withRouter(connect(mapStateToProps, null)(Header));

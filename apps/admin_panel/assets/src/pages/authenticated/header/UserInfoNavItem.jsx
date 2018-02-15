import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import { getTranslate } from 'react-localize-redux';
import { Image, Nav, NavItem, NavDropdown, MenuItem } from 'react-bootstrap';
import defaultAvatar from '../../../../public/images/user.svg';
import Actions from './actions';

const defaultEmail = 'default@omisego.co';

const UserInfoNavItem = ({
  accountPath, currentUser, history, translate, logout,
}) => (
  <Nav className="omg-nav" pullRight>
    <NavItem className="omg-nav__avatar" eventKey={3} href="#" id="avatar">
      <Image
        circle
        src={(currentUser && currentUser.avatar && currentUser.avatar.small) || defaultAvatar}
      />
    </NavItem>
    <NavDropdown
      className="omg-dropdown__gray"
      eventKey={4}
      id={4}
      title={(currentUser && currentUser.email) || defaultEmail}
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
        onClick={logout}
      >
        {translate('header.logout')}
      </MenuItem>
    </NavDropdown>
  </Nav>
);

UserInfoNavItem.propTypes = {
  accountPath: PropTypes.string.isRequired,
  currentUser: PropTypes.object.isRequired,
  history: PropTypes.object.isRequired,
  logout: PropTypes.func.isRequired,
  translate: PropTypes.func.isRequired,
};

const mapDispatchToProps = dispatch => ({
  logout: () => dispatch(Actions.logout()),
});

const mapStateToProps = (state) => {
  const { session } = state;
  const { currentUser } = session;
  const translate = getTranslate(state.locale);
  return {
    currentUser,
    session,
    translate,
  };
};

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(UserInfoNavItem));

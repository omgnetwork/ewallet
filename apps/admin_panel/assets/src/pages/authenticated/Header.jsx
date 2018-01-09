import React from 'react';
import { Image, Navbar, Nav, NavItem, NavDropdown, MenuItem } from 'react-bootstrap';

import logo from '../../../public/images/omisego_logo_white.png';
import avatar from '../../../public/images/user.svg';

const Header = () => (
  <div className="row">
    <div>
      <div className="header">
        <Navbar className="header header__navbar" collapseOnSelect fixedTop staticTop>
          <div className="col-md-3 col-xs-12 col-sm-4">
            <Navbar.Header className="col-md-10 col-md-offset-1 col-xs-12 col-sm-12">
              <Navbar.Brand>
                <Image className="header__logo" src={logo} />
              </Navbar.Brand>
              <Navbar.Toggle />
            </Navbar.Header>
          </div>
          <div className="col-md-9 col-sm-8 col-xs-12">
            <Navbar.Collapse>
              <Nav className="header__button-toolbar">
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
                  <Image circle src={avatar} />
                </NavItem>
                <NavItem className="omg-nav__user-info" eventKey={4} href="#">
                  First name
                </NavItem>
                <Navbar.Text>
                  |
                </Navbar.Text>
                <NavItem className="omg-nav__user-info" eventKey={6} href="#">
                  Admin
                </NavItem>
              </Nav>
            </Navbar.Collapse>
          </div>
        </Navbar>
      </div>
    </div>
  </div>
);
export default Header;

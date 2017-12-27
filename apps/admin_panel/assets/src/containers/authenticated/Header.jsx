import React, { Component } from "react";
import { Image, Navbar, Nav, NavItem, NavDropdown, MenuItem, ButtonToolbar, DropdownButton, NavbarToggle } from 'react-bootstrap';

import logo from "../../../public/images/omisego_logo_white.png"
import avatar from "../../../public/images/user.svg"

class Header extends Component {
  render() {
    return (
      <div className="row">
        <div>
          <div className="header">
            <Navbar collapseOnSelect className="header header__navbar" fixedTop staticTop>
              <div className="col-md-3 col-xs-12 col-sm-4">
              <Navbar.Header className="col-md-10 col-md-offset-1 col-xs-12 col-sm-12" >
                <Navbar.Brand>
                  <Image className="header__logo" src={logo} />
                </Navbar.Brand>
                <Navbar.Toggle />
              </Navbar.Header>
              </div>
              <div className="col-md-9 col-sm-8 col-xs-12">
              <Navbar.Collapse>
                <Nav className="header__button-toolbar">
                  <NavDropdown eventKey={1} title="Select Accounts" id="omg-nav-dropdown" className="omg-dropdown">
                    <MenuItem eventKey={1.2}>Account 1</MenuItem>
                    <MenuItem eventKey={1.3}>Account 2</MenuItem>
                    <MenuItem eventKey={1.3}>Account 3</MenuItem>
                  </NavDropdown>
                </Nav>
                <Nav pullRight className="omg-nav">
                  <NavItem eventKey={3} id="avatar" className="omg-nav__avatar" href="#">
                    <Image src={avatar} circle />
                  </NavItem>
                  <NavItem eventKey={4} href="#" className="omg-nav__user-info">First name</NavItem>
                  <Navbar.Text>|</Navbar.Text>
                  <NavItem eventKey={6} href="#" className="omg-nav__user-info">Admin</NavItem>
                </Nav>
              </Navbar.Collapse>
              </div>
            </Navbar>
          </div>
        </div>
      </div>
    );
  }
}

export default Header;

import React, { Component } from "react";
import { Image, Navbar, Nav, NavItem, NavDropdown, MenuItem } from 'react-bootstrap';

import logo from "../../../public/images/omisego_logo_white.png"

class Header extends Component {
  render() {
    return (
        <div className="row">
          <div className="col-xs-12">
            <div className="header">
              <Navbar collapseOnSelect className="header__navbar fh">
                <Navbar.Header>
                  <Navbar.Brand>
                    <Image className="header__logo" src={logo} />
                  </Navbar.Brand>
                  <Navbar.Toggle />
                </Navbar.Header>
                <Navbar.Collapse>
                  <Nav>
                    <NavDropdown eventKey={1} title="Select Accounts" id="basic-nav-dropdown">
                      <MenuItem eventKey={1.1}>Minor Group</MenuItem>
                      <MenuItem divider />
                      <MenuItem eventKey={1.2}>Merchant 1</MenuItem>
                      <MenuItem eventKey={1.3}>Merchant 2</MenuItem>
                      <MenuItem eventKey={1.3}>Merchant 3</MenuItem>
                    </NavDropdown>
                  </Nav>
                  <Nav pullRight>
                    <NavItem eventKey={2} href="#">First name</NavItem>
                    <NavItem eventKey={3} href="#">Admin</NavItem>
                  </Nav>
                </Navbar.Collapse>
              </Navbar>
          </div>
        </div>
      </div>
    );
  }
}

export default Header;

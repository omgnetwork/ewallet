import React, { Component } from "react";
import { withRouter, Link } from "react-router-dom";

class SidebarLink extends Component {
  render() {
    const { title, to, currentPath } = this.props
    return (
      <Link to={to} className={"sidebar__link" + (currentPath === to ? " sidebar__link--active" : "")}>{title}</Link>
    );
  }
}

export default SidebarLink;

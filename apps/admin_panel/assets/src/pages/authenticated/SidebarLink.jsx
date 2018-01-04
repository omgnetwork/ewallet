import React from 'react';
import { Link } from 'react-router-dom';
import PropTypes from 'prop-types';

const SidebarLink = ({ title, to, currentPath }) => (
  <Link to={to} href={to} className={`sidebar__link${currentPath === to ? ' sidebar__link--active' : ''}`}>
    {title}
  </Link>
);

SidebarLink.propTypes = {
  title: PropTypes.string.isRequired,
  to: PropTypes.string.isRequired,
  currentPath: PropTypes.string.isRequired,
};

export default SidebarLink;

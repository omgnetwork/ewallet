import React from 'react';
import { Link } from 'react-router-dom';
import PropTypes from 'prop-types';

const SidebarLink = ({ title, to, currentPath }) => (
  <Link
    className={`sidebar__link${currentPath === to ? ' sidebar__link--active' : ''}`}
    href={to}
    to={to}
  >
    {title}
  </Link>
);

SidebarLink.propTypes = {
  currentPath: PropTypes.string.isRequired,
  title: PropTypes.string.isRequired,
  to: PropTypes.string.isRequired,
};

export default SidebarLink;

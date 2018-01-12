import React from 'react';
import { localize } from 'react-localize-redux';
import { Button, Glyphicon, Dropdown, MenuItem } from 'react-bootstrap';
import PropTypes from 'prop-types';
import OMGSearchField from '../../../../components/OMGSearchField';

const UsersHeader = ({
  translate, query, handleSearchChange, handleNewUser,
}) => (
  <div className="search-header">
    <div className="row mb-3">
      <div className="col-md-6">
        <h1 className="search-header__title pull-left">
          {translate('users.header.users')}
        </h1>
      </div>
      <div className="col-md-6">
        <Button
          bsClass="search-header__new_button btn btn-omg-blue pull-right"
          bsStyle="primary"
          onClick={handleNewUser}
        >
          <Glyphicon glyph="plus" />
          {translate('users.header.new_user')}
        </Button>
      </div>
    </div>
    <div className="row mb-1">
      <div className="col-md-3">
        <OMGSearchField handleSearchChange={handleSearchChange} query={query} />
      </div>
      <div className="col-md-3">
        <Button bsClass="search-header__adv_filter_btn btn" bsStyle="link">
          {translate('users.header.advanced_filters')}
        </Button>
      </div>
      <div className="col-md-6">
        <Dropdown
          className="search-header__dropdown-export pull-right"
          id="search-header__dropdown-export"
        >
          <Dropdown.Toggle className="search-header__dropdown-toggle">
            <Glyphicon glyph="share" />
            {translate('users.header.export')}
          </Dropdown.Toggle>
          <Dropdown.Menu>
            <MenuItem eventKey="1">
              CSV
            </MenuItem>
          </Dropdown.Menu>
        </Dropdown>
      </div>
    </div>
  </div>
);

UsersHeader.propTypes = {
  handleNewUser: PropTypes.func.isRequired,
  handleSearchChange: PropTypes.func.isRequired,
  query: PropTypes.string.isRequired,
  translate: PropTypes.func.isRequired,
};

export default localize(UsersHeader, 'locale');

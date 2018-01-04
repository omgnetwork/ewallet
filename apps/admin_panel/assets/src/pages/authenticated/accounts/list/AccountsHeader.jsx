import React from 'react';
import { localize } from 'react-localize-redux';
import { Button, Glyphicon, Dropdown, MenuItem } from 'react-bootstrap';
import PropTypes from 'prop-types';
import OMGSearchField from '../../../../components/OMGSearchField';

const AccountsHeader = ({
  translate, query, onSearchChange, onNewAccount,
}) => (
  <div className="accounts-header">
    <div className="row mb-3">
      <div className="col-md-6">
        <h1 className="accounts-header__title pull-left">
          {translate('accounts.header.accounts')}
        </h1>
      </div>
      <div className="col-md-6">
        <Button
          bsClass="accounts-header__new_button btn btn-omg-blue pull-right"
          bsStyle="primary"
          onClick={onNewAccount}
        >
          <Glyphicon glyph="plus" />
          {translate('accounts.header.new_account')}
        </Button>
      </div>
    </div>
    <div className="row mb-1">
      <div className="col-md-3">
        <OMGSearchField query={query} onSearchChange={onSearchChange} />
      </div>
      <div className="col-md-3">
        <Button bsClass="accounts-header__adv_filter_btn btn" bsStyle="link">
          {translate('accounts.header.advanced_filters')}
        </Button>
      </div>
      <div className="col-md-6">
        <Dropdown
          className="accounts-header__dropdown-export pull-right"
          id="accounts-header__dropdown-export"
        >
          <Dropdown.Toggle className="accounts-header__dropdown-toggle">
            <Glyphicon glyph="share" />
            {translate('accounts.header.export')}
          </Dropdown.Toggle>
          <Dropdown.Menu>
            <MenuItem eventKey="1">CSV</MenuItem>
          </Dropdown.Menu>
        </Dropdown>
      </div>
    </div>
  </div>
);

AccountsHeader.propTypes = {
  translate: PropTypes.func.isRequired,
  query: PropTypes.string.isRequired,
  onSearchChange: PropTypes.func.isRequired,
  onNewAccount: PropTypes.func.isRequired,
};

export default localize(AccountsHeader, 'locale');

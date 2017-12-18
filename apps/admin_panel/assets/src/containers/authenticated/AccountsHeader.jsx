import React, { Component } from "react";
import { connect } from "react-redux";
import { getTranslate } from 'react-localize-redux';
import { Button, Glyphicon, Dropdown, MenuItem } from "react-bootstrap"

import OMGSearchField from "../../components/OMGSearchField"

class AccountsHeader extends Component {

  render() {
    const { translate, query, handleSubmit } = this.props;
    return(
      <div className="accounts-header">
        <div className="row mb-3">
          <div className="col-md-6">
            <h1 className="accounts-header__title pull-left">
              {translate("accounts.header.accounts")}
            </h1>
          </div>
          <div className="col-md-6">
            <Button bsClass="accounts-header__new_button btn btn-omg-blue pull-right" bsStyle="primary" >
              <Glyphicon glyph="plus" />
              {translate("accounts.header.new_account")}
            </Button>
          </div>
        </div>
        <div className="row mb-1">
          <div className="col-md-3">
            <OMGSearchField
              query={query}
              handleSubmit={handleSubmit}
            />
          </div>
          <div className="col-md-3">
            <Button bsClass="accounts-header__adv_filter_btn btn" bsStyle="link" >
              {translate("accounts.header.advanced_filters")}
            </Button>
          </div>
          <div className="col-md-6">
            <Dropdown className="accounts-header__dropdown-export pull-right" id="accounts-header__dropdown-export">
              <Dropdown.Toggle className="accounts-header__dropdown-toggle">
                <Glyphicon glyph="share" />
                {translate("accounts.header.export")}
              </Dropdown.Toggle>
              <Dropdown.Menu>
                <MenuItem eventKey="1">CSV</MenuItem>
              </Dropdown.Menu>
            </Dropdown>
          </div>
        </div>
      </div>
    );
  }
}

function mapStateToProps(state) {
  const translate = getTranslate(state.locale);
  return {
    translate
  };
}

export default connect(mapStateToProps)(AccountsHeader);

import React, { Component } from "react";
import { Button } from 'react-bootstrap';
import { localize } from 'react-localize-redux';

class PublicFooter extends Component {
  render() {
    const { translate } = this.props;
    return (
      <div className="public-footer">
        <ul className="list-inline">
        <li>
          <Button
            className="list-inline-item public-footer__link"
            bsStyle="link"
            href="https://omisego.network"
          >
            {translate("public-footer.about")}
          </Button>
          </li>
          <li>
            <Button
              className="list-inline-item public-footer__link"
              bsStyle="link"
              href="https://omisego.network"
            >
              {translate("public-footer.documentation")}
            </Button>
          </li>
          <li>
            <Button
              className="list-inline-item public-footer__link"
              bsStyle="link"
              href="https://omisego.network"
            >
              {translate("public-footer.help")}
            </Button>
          </li>
          <li>
            <Button
              className="list-inline-item public-footer__link"
              bsStyle="link"
              href="https://omisego.network"
            >
              {translate("public-footer.terms")}
            </Button>
          </li>
          <li>
            <Button
              className="list-inline-item public-footer__link"
              bsStyle="link"
              href="https://omisego.network"
            >
              {translate("public-footer.privacy")}
            </Button>
          </li>
        </ul>
      </div>
    );
  }
}

export default localize(PublicFooter, 'locale');

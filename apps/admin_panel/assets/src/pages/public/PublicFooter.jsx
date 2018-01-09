import React from 'react';
import { Button } from 'react-bootstrap';
import { localize } from 'react-localize-redux';
import PropTypes from 'prop-types';

const PublicFooter = ({ translate }) => (
  <div className="public-footer">
    <ul className="list-inline">
      <li>
        <Button
          bsStyle="link"
          className="list-inline-item public-footer__link"
          href="https://omisego.network"
        >
          {translate('public-footer.about')}
        </Button>
      </li>
      <li>
        <Button
          bsStyle="link"
          className="list-inline-item public-footer__link"
          href="https://omisego.network"
        >
          {translate('public-footer.documentation')}
        </Button>
      </li>
      <li>
        <Button
          bsStyle="link"
          className="list-inline-item public-footer__link"
          href="https://omisego.network"
        >
          {translate('public-footer.help')}
        </Button>
      </li>
      <li>
        <Button
          bsStyle="link"
          className="list-inline-item public-footer__link"
          href="https://omisego.network"
        >
          {translate('public-footer.terms')}
        </Button>
      </li>
      <li>
        <Button
          bsStyle="link"
          className="list-inline-item public-footer__link"
          href="https://omisego.network"
        >
          {translate('public-footer.privacy')}
        </Button>
      </li>
    </ul>
  </div>
);

PublicFooter.propTypes = {
  translate: PropTypes.func.isRequired,
};

export default localize(PublicFooter, 'locale');

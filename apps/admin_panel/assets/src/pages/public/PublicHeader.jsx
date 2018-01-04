import React from 'react';
import { Image } from 'react-bootstrap';

import logo from '../../../public/images/omisego_logo_black.png';

const PublicHeader = () => (
  <div className="row">
    <div className="col-xs-12">
      <div className="public-header">
        <Image className="public-header__logo" src={logo} responsive />
      </div>
    </div>
  </div>
);

export default PublicHeader;

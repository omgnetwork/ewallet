import React, { Component } from "react";
import { Button } from 'react-bootstrap';

class PublicFooter extends Component {
  render() {
    return (
      <div className="public-footer">
        <ul className="list-inline">
          <li><Button className="list-inline-item public-footer__link" bsStyle="link" href="https://omisego.network">About</Button></li>
          <li><Button className="list-inline-item public-footer__link" bsStyle="link" href="https://omisego.network">Documentation</Button></li>
          <li><Button className="list-inline-item public-footer__link" bsStyle="link" href="https://omisego.network">Help</Button></li>
          <li><Button className="list-inline-item public-footer__link" bsStyle="link" href="https://omisego.network">Terms</Button></li>
          <li><Button className="list-inline-item public-footer__link" bsStyle="link" href="https://omisego.network">Privacy</Button></li>
        </ul>
      </div>
    );
  }
}

export default PublicFooter;

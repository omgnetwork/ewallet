import React, { Component } from "react";
import { Button } from 'react-bootstrap';

class ExternalFooter extends Component {
  render() {
    return (
      <div className="external-footer">
        <ul>
          <li><Button bsStyle="link" href="https://omisego.network">About</Button></li>
          <li><Button bsStyle="link" href="https://omisego.network">Documentation</Button></li>
          <li><Button bsStyle="link" href="https://omisego.network">Help</Button></li>
          <li><Button bsStyle="link" href="https://omisego.network">Terms</Button></li>
          <li><Button bsStyle="link" href="https://omisego.network">Privacy</Button></li>
        </ul>
      </div>
    );
  }
}

export default ExternalFooter;

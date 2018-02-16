import React, { Component } from 'react';
import PropTypes from 'prop-types';
import FA from 'react-fontawesome';
import { Button } from 'react-bootstrap';
import { localize } from 'react-localize-redux';
import copyToClipboard from '../helpers/copier';

class OMGTruncatedCell extends Component {
  static shortenedString(string) {
    const shorteningLength = 5;
    return (string.length > shorteningLength) ? `${string.substr(0, shorteningLength)}...` : string;
  }

  render() {
    const { content } = this.props;
    return (
      <span>
        {OMGTruncatedCell.shortenedString(content)}
        <Button bsStyle="link" onClick={() => copyToClipboard(content)}>
          <FA name="copy" />
        </Button>
      </span>
    );
  }
}

OMGTruncatedCell.propTypes = {
  content: PropTypes.string.isRequired,
};

export default localize(OMGTruncatedCell, 'locale');

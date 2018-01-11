import React, { Component } from 'react';
import { Button, Glyphicon, FormGroup, FormControl, InputGroup } from 'react-bootstrap';
import PropTypes from 'prop-types';

class OMGSearchField extends Component {
  constructor(props) {
    super(props);
    this.state = {
      query: props.query,
    };
    this.handleFilterTextChange = this.handleFilterTextChange.bind(this);
    this.handleSubmit = this.handleSubmit.bind(this);
  }

  componentWillReceiveProps(nextProps) {
    const { query } = this.props;
    if (nextProps.query !== query) {
      this.setState({ query: nextProps.query });
    }
  }

  handleFilterTextChange(e) {
    const { value } = e.target;
    this.setState({ query: value });
  }

  handleSubmit(e) {
    e.preventDefault();
    const { query } = this.state;
    const { handleSearchChange } = this.props;
    handleSearchChange(query);
  }

  render() {
    const { query } = this.state;
    return (
      <form className="omg-serch-field" onSubmit={this.handleSubmit}>
        <FormGroup>
          <InputGroup>
            <FormControl
              className="omg-serch-field__input"
              onChange={this.handleFilterTextChange}
              placeholder="Search"
              type="text"
              value={query}
            />
            <InputGroup.Addon className="omg-serch-field__addon">
              <Button
                bsClass="omg-serch-field__submit"
                type="submit"
              >
                <Glyphicon glyph="search" />
              </Button>
            </InputGroup.Addon>
          </InputGroup>
        </FormGroup>
      </form>
    );
  }
}

OMGSearchField.propTypes = {
  handleSearchChange: PropTypes.func.isRequired,
  query: PropTypes.string.isRequired,
};

export default OMGSearchField;

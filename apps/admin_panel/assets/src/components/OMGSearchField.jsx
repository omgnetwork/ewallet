import React, { Component } from "react";
import { Button, Glyphicon, FormGroup, FormControl, InputGroup } from "react-bootstrap"

class OMGSearchField extends Component {

  constructor(props) {
    super(props);
    this.state = {
      query: props.query
    };
    this.handleFilterTextChange = this.handleFilterTextChange.bind(this);
    this.handleSubmit = this.handleSubmit.bind(this);
  }

  componentWillUpdate(nextProps) {
    const { query } = this.props;
    if (nextProps.query !== query) {
      this.setState({query: nextProps.query})
    }
  }

  handleFilterTextChange(e) {
    const { value } = e.target;
    this.setState({query: value})
  }

  handleSubmit(e) {
    e.preventDefault();
    const { query } = this.state
    const { onSearchChange } = this.props
    onSearchChange(query);
  }

  render() {
    return(
      <form className="omg-serch-field" onSubmit={this.handleSubmit}>
        <FormGroup>
          <InputGroup>
            <FormControl
              className="omg-serch-field__input"
              type="text"
              placeholder="Search"
              value={this.state.query}
              onChange={this.handleFilterTextChange}
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

export default OMGSearchField

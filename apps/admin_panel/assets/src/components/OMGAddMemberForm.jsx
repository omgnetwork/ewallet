import React, { Component } from 'react';
import PropTypes from 'prop-types';
import { localize } from 'react-localize-redux';
import { Form, FormGroup, InputGroup, DropdownButton, MenuItem, Button } from 'react-bootstrap';
import { AsyncTypeahead } from 'react-bootstrap-typeahead';
import 'react-bootstrap-typeahead/css/Typeahead.css';

class OMGAddMemberForm extends Component {
  constructor(props) {
    super(props);
    const {
      defaultInputValue, defaultDropdownValue, roles, translate,
    } = this.props;
    this.state = {
      dropdownSelectedItem: defaultDropdownValue || translate(roles[0].label),
      inputValue: defaultInputValue,
      isLoading: false,
      dropdownOptions: roles,
    };
    this.handleChange = this.handleChange.bind(this);
    this.setTypeaheadComponent = this.setTypeaheadComponent.bind(this);
    this.handleSearchResult = this.handleSearchResult.bind(this);
    this.handleAddClicked = this.handleAddClicked.bind(this);
    this.handleInputChanged = this.handleInputChanged.bind(this);
  }

  componentDidMount() {
    const { inputValue } = this.state;
    /* A little bit hacky since react-bootstrap-typeahead
     * doesn't provide method to set the initial value.
     * So I need to get access to their private method (_updateText) to set it manually.
     */
    this.typeahead._updateText(inputValue); // eslint-disable-line no-underscore-dangle
  }

  setTypeaheadComponent(component) {
    if (component != null) {
      this.typeahead = component.getInstance();
    }
  }

  handleChange(eventKey, event) {
    // eslint-disable-line no-unused-vars
    const { translate } = this.props;
    this.setState({ dropdownSelectedItem: translate(eventKey.label) });
  }

  handleSearchResult(query) {
    const { onSearch } = this.props;
    if (!onSearch) return;
    this.setState({ isLoading: true });
    onSearch(query).then(options => this.setState({ dropdownOptions: options, isLoading: false }));
  }

  handleAddClicked() {
    const { text } = this.state; // eslint-disable-line no-unused-vars
  }

  handleInputChanged(text) {
    this.setState({
      inputValue: text,
    });
  }

  render() {
    const {
      placeholder, roles, customRenderMenuItem, labelKey, minLength, translate,
    } = this.props;
    const { dropdownSelectedItem, dropdownOptions, isLoading } = this.state;
    const dropdownItems = roles.map((v, index) => (
      <MenuItem key={index} eventKey={v}>
        {translate(v.label)}
      </MenuItem>
    ));

    return (
      <div>
        <Form className="omg-add-member-form" inline>
          <FormGroup>
            <InputGroup>
              <AsyncTypeahead
                ref={component => this.setTypeaheadComponent(component)}
                className="omg-add-member-form__input"
                isLoading={isLoading}
                labelKey={labelKey}
                minLength={minLength}
                onInputChange={this.handleInputChanged}
                onSearch={this.handleSearchResult}
                options={dropdownOptions}
                placeholder={translate(placeholder)}
                renderMenuItemChildren={customRenderMenuItem}
              />
              <DropdownButton
                className="omg-add-member-form__dropdown"
                componentClass={InputGroup.Button}
                id="omg-add-member-dropdown"
                onSelect={this.handleChange}
                title={dropdownSelectedItem}
              >
                {dropdownItems}
              </DropdownButton>
            </InputGroup>
          </FormGroup>
          <Button
            bsClass="btn btn-omg-blue"
            bsStyle="primary"
            onClick={this.handleAddClicked}
            type="button"
          >
            {translate('components.omg_add_member_form.add')}
          </Button>
        </Form>
      </div>
    );
  }
}

OMGAddMemberForm.propTypes = {
  customRenderMenuItem: PropTypes.func,
  defaultDropdownValue: PropTypes.string,
  defaultInputValue: PropTypes.string,
  labelKey: PropTypes.string.isRequired, // This is `key` of the object where points to the value.
  minLength: PropTypes.number,
  onSearch: PropTypes.func,
  placeholder: PropTypes.string,
  roles: PropTypes.arrayOf(PropTypes.shape({
    label: PropTypes.string,
    value: PropTypes.string,
  })),
  translate: PropTypes.func.isRequired,
};

OMGAddMemberForm.defaultProps = {
  customRenderMenuItem: null,
  placeholder: 'components.omg_add_member_form.placeholder',
  minLength: 2,
  roles: [{ label: 'components.omg_add_member_form.select_item', value: 'select_item' }],
  onSearch: null,
  defaultInputValue: '',
  defaultDropdownValue: '',
};

export default localize(OMGAddMemberForm, 'locale');

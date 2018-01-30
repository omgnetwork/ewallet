import React, { Component } from 'react';
import PropTypes from 'prop-types';
import { localize } from 'react-localize-redux';
import { Form, FormGroup, InputGroup, DropdownButton, MenuItem } from 'react-bootstrap';
import { AsyncTypeahead } from 'react-bootstrap-typeahead';
import 'react-bootstrap-typeahead/css/Typeahead.css';
import OMGLoadingButton from './OMGLoadingButton';
import { upperCaseFirst } from '../helpers/stringFormatter';

class OMGAddMemberForm extends Component {
  static actionType() {
    return {
      add: 'add',
      update: 'update',
      remove: 'remove',
    };
  }

  constructor(props) {
    super(props);
    const {
      member, roles, translate, typeaheadOptions,
    } = this.props;
    this.state = {
      dropdownSelectedItem: member.accountRole || translate(roles[0].label),
      inputValue: member.email,
      isLoading: false,
      typeaheadOptions,
      enableAddMember: false,
    };
    this.handleChange = this.handleChange.bind(this);
    this.setTypeaheadComponent = this.setTypeaheadComponent.bind(this);
    this.handleSearchResult = this.handleSearchResult.bind(this);
    this.handleInputChanged = this.handleInputChanged.bind(this);
    this.handleAddClick = this.handleAddClick.bind(this);
    this.handleUpdateClick = this.handleUpdateClick.bind(this);
    this.handleEnter = this.handleEnter.bind(this);
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

  handleChange(eventKey, event) { // eslint-disable-line no-unused-vars
    const { translate } = this.props;
    this.setState({ dropdownSelectedItem: translate(eventKey.label) });
  }

  handleSearchResult(query) {
    const { onSearch } = this.props;
    if (!onSearch) return;
    this.setState({ isLoading: true });
    onSearch(query, (members) => {
      this.setState({ typeaheadOptions: members, isLoading: false });
    });
  }

  handleInputChanged(text) {
    const isEmailValid = /^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,})+$/.test(text);
    this.setState({
      enableAddMember: isEmailValid,
      inputValue: text,
    });
  }

  handleEnter(event) {
    if (event.key === 'Enter') {
      this.handleAddClick();
    }
  }

  handleAddClick() {
    const { inputValue, dropdownSelectedItem, typeaheadOptions } = this.state;
    const { onAdd } = this.props;
    const newMember = typeaheadOptions.filter(member => member.email === inputValue);

    if (newMember[0]) {
      onAdd(
        { ...newMember[0], accountRole: dropdownSelectedItem },
        OMGAddMemberForm.actionType().add,
      );
      this.setState({
        inputValue: '',
      }, () => {
        this.typeahead.clear();
      });
    } else {
      onAdd({
        email: inputValue,
        status: 'pending_confirmation',
        accountRole: dropdownSelectedItem,
      }, OMGAddMemberForm.actionType().add);
    }
  }

  handleUpdateClick() {
    const { inputValue, dropdownSelectedItem } = this.state;
    const { onUpdate } = this.props;
    onUpdate(
      { email: inputValue, accountRole: dropdownSelectedItem },
      OMGAddMemberForm.actionType().update,
    );
  }

  render() {
    const {
      placeholder,
      roles,
      customRenderMenuItem,
      labelKey,
      loading,
      minLength,
      onCancel,
      onRemove,
      translate,
      isDisabledTextInput,
      isEdit,
      member,
    } = this.props;
    const {
      dropdownSelectedItem, isLoading, typeaheadOptions, enableAddMember,
    } = this.state;
    const dropdownItems = roles.map((v, index) => (
      <MenuItem key={index} eventKey={v}>
        {translate(v.label)}
      </MenuItem>
    ));

    const actionButton = isEdit ? (
      <div className="omg-add-member-form__button-group">
        <OMGLoadingButton
          disabled={loading.addMember || loading.removeMember || loading.updateMember}
          loading={loading.updateMember}
          onClick={this.handleUpdateClick}
        >
          {translate('components.omg_add_member_form.update')}
        </OMGLoadingButton>
        <OMGLoadingButton
          className="btn-omg-red"
          disabled={loading.addMember || loading.removeMember || loading.updateMember}
          loading={loading.removeMember}
          onClick={() => onRemove(member, OMGAddMemberForm.actionType().remove)}
        >
          {translate('components.omg_add_member_form.remove')}
        </OMGLoadingButton>
        <OMGLoadingButton
          className="btn-omg-white"
          disabled={loading.addMember || loading.removeMember || loading.updateMember}
          onClick={() => onCancel()}
        >
          {translate('components.omg_add_member_form.cancel')}
        </OMGLoadingButton>
      </div>
    ) : (
      <OMGLoadingButton
        disabled={!enableAddMember}
        loading={loading.addMember}
        onClick={this.handleAddClick}
      >
        {translate('components.omg_add_member_form.add')}
      </OMGLoadingButton>
    );

    return (
      <div>
        <Form className="omg-add-member-form" inline>
          <FormGroup>
            <InputGroup>
              <AsyncTypeahead
                ref={component => this.setTypeaheadComponent(component)}
                className="omg-add-member-form__input"
                disabled={isDisabledTextInput}
                filterBy={['email', 'id']}
                isLoading={isLoading}
                labelKey={labelKey}
                minLength={minLength}
                onInputChange={this.handleInputChanged}
                onKeyDown={this.handleEnter}
                onSearch={this.handleSearchResult}
                options={typeaheadOptions}
                placeholder={translate(placeholder)}
                renderMenuItemChildren={customRenderMenuItem}
              />
              <DropdownButton
                className="omg-add-member-form__dropdown"
                componentClass={InputGroup.Button}
                id="omg-add-member-dropdown"
                onSelect={this.handleChange}
                title={upperCaseFirst(dropdownSelectedItem)}
              >
                {dropdownItems}
              </DropdownButton>
            </InputGroup>
          </FormGroup>
          {actionButton}
        </Form>
      </div>
    );
  }
}

OMGAddMemberForm.propTypes = {
  customRenderMenuItem: PropTypes.func,
  isDisabledTextInput: PropTypes.bool,
  isEdit: PropTypes.bool,
  labelKey: PropTypes.string.isRequired, // This is `key` of the object where points to the value.
  loading: PropTypes.shape({
    addMember: PropTypes.bool,
    removeMember: PropTypes.bool,
    updateMember: PropTypes.bool,
  }),
  member: PropTypes.shape({
    id: PropTypes.string,
    name: PropTypes.string,
    accountRole: PropTypes.string,
    email: PropTypes.string,
  }),
  minLength: PropTypes.number,
  onAdd: PropTypes.func,
  onCancel: PropTypes.func,
  onRemove: PropTypes.func,
  onSearch: PropTypes.func,
  onUpdate: PropTypes.func,
  placeholder: PropTypes.string,
  roles: PropTypes.arrayOf(PropTypes.shape({
    label: PropTypes.string,
    value: PropTypes.string,
  })),
  translate: PropTypes.func.isRequired,
  typeaheadOptions: PropTypes.arrayOf(PropTypes.shape({
    email: PropTypes.string,
  })),
};

OMGAddMemberForm.defaultProps = {
  customRenderMenuItem: null,
  isEdit: false,
  isDisabledTextInput: false,
  placeholder: 'components.omg_add_member_form.placeholder',
  minLength: 2,
  loading: {
    addMember: false,
    removeMember: false,
    updateMember: false,
  },
  roles: [{ label: 'components.omg_add_member_form.select_item', value: 'select_item' }],
  onAdd: null,
  onRemove: null,
  onCancel: null,
  onSearch: null,
  onUpdate: null,
  member: {
    id: '',
    name: '',
    accountRole: '',
    email: '',
  },
  typeaheadOptions: [],
};

export default localize(OMGAddMemberForm, 'locale');

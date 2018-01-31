import ResetPasswordForm, { UPDATE_PASSWORD } from '../ResetPasswordForm';
import { ShallowComponentTester } from '../../../../../__tests__/ComponentTester';
import { validEmail, invalidEmail, validParams } from './stubs';
import { formatEmailLink } from '../../../../helpers/urlFormatter';

describe('ResetPasswordForm', () => {
  const resetPassword = jest.fn();
  const onSuccess = jest.fn();
  test('handleChange changes the state', () => {
    const component =
      ShallowComponentTester(ResetPasswordForm, { loading: false, resetPassword, onSuccess });
    const emailInputEvent = { target: { id: 'email', value: validEmail } };
    expect(component.state('email')).toEqual('');
    component.instance().handleChange(emailInputEvent);
    expect(component.state('email')).toEqual(validEmail);
  });

  test('resetPassword function is called with right params', () => {
    const component =
      ShallowComponentTester(ResetPasswordForm, { loading: false, resetPassword, onSuccess });
    const emailInputEvent = { target: { id: 'email', value: validEmail } };
    component.find('[type="text"]').at(0).simulate('change', emailInputEvent);
    component.find('form').simulate('submit', { preventDefault: jest.fn() });
    expect(resetPassword).toBeCalledWith({
      email: validEmail, url: formatEmailLink(UPDATE_PASSWORD),
    }, onSuccess);
  });

  test('submit button is enabled if state is valid', () => {
    const component =
      ShallowComponentTester(ResetPasswordForm, { loading: false, resetPassword, onSuccess });
    component.setState(validParams);
    const submitButton = component.find('[type="submit"]').get(0);
    expect(submitButton.props.disabled).toBe(false);
  });

  test('submit button is disabled if state is invalid', () => {
    const component =
      ShallowComponentTester(ResetPasswordForm, { loading: false, resetPassword, onSuccess });
    component.setState({ email: invalidEmail });
    const submitButton = component.find('[type="submit"]').get(0);
    expect(submitButton.props.disabled).toBe(true);
  });
});

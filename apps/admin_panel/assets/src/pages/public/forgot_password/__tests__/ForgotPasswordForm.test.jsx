import Enzyme from 'enzyme';
import Adapter from 'enzyme-adapter-react-16';
import ForgotPasswordForm from '../ForgotPasswordForm';
import { ShallowComponentTester } from '../../../../../__tests__/ComponentTester';
import { validEmail, invalidEmail, validParams } from './stubs';
import { OMISEGO_BASE_URL } from '../../../../omisego/config';

Enzyme.configure({ adapter: new Adapter() });

describe('ForgotPasswordForm', () => {
  const forgotPassword = jest.fn();
  const onSuccess = jest.fn();
  test('handleChange changes the state', () => {
    const component =
      ShallowComponentTester(ForgotPasswordForm, { loading: false, forgotPassword, onSuccess });
    const emailInputEvent = { target: { id: 'email', value: validEmail } };
    expect(component.state('email')).toEqual('');
    component.instance().handleChange(emailInputEvent);
    expect(component.state('email')).toEqual(validEmail);
  });

  test('forgotPassword function is called with right params', () => {
    const component =
      ShallowComponentTester(ForgotPasswordForm, { loading: false, forgotPassword, onSuccess });
    const emailInputEvent = { target: { id: 'email', value: validEmail } };
    component.find('[type="text"]').at(0).simulate('change', emailInputEvent);
    component.find('form').simulate('submit', { preventDefault: jest.fn() });
    expect(forgotPassword).toBeCalledWith({ email: validEmail, url: OMISEGO_BASE_URL }, onSuccess);
  });

  test('submit button is enabled if state is valid', () => {
    const component =
      ShallowComponentTester(ForgotPasswordForm, { loading: false, forgotPassword, onSuccess });
    component.setState(validParams);
    const submitButton = component.find('[type="submit"]').get(0);
    expect(submitButton.props.disabled).toBe(false);
  });

  test('submit button is disabled if state is invalid', () => {
    const component =
      ShallowComponentTester(ForgotPasswordForm, { loading: false, forgotPassword, onSuccess });
    component.setState({ email: invalidEmail });
    const submitButton = component.find('[type="submit"]').get(0);
    expect(submitButton.props.disabled).toBe(true);
  });
});

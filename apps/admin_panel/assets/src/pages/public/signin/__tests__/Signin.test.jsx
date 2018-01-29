import Enzyme from 'enzyme';
import Adapter from 'enzyme-adapter-react-16';
import SignIn from '../SignIn';
import { validEmail, validPassword, invalidEmail, invalidPassword, validParams } from './stubs';
import { ShallowComponentTester } from '../../../../../__tests__/ComponentTester';

Enzyme.configure({ adapter: new Adapter() });

describe('SignIn', () => {
  test('handleChange changes the state', () => {
    const login = jest.fn();
    const component = ShallowComponentTester(SignIn, { loading: false, login });
    const emailInputEvent = { target: { id: 'email', value: validEmail } };
    expect(component.state('email')).toEqual('');
    component.instance().handleChange(emailInputEvent);
    expect(component.state('email')).toEqual(validEmail);
  });

  test('login function is called with right params', () => {
    const login = jest.fn();
    const component = ShallowComponentTester(SignIn, { loading: false, login });
    const emailInputEvent = { target: { id: 'email', value: validEmail } };
    component.find('[type="text"]').at(0).simulate('change', emailInputEvent);
    const passwordInputEvent = { target: { id: 'password', value: validPassword } };
    component.find('[type="password"]').at(0).simulate('change', passwordInputEvent);
    component.find('form').simulate('submit', { preventDefault: jest.fn() });
    expect(login).toBeCalledWith({ email: validEmail, password: validPassword });
  });

  test('submit button is enabled if state is valid', () => {
    const login = jest.fn();
    const component = ShallowComponentTester(SignIn, { loading: false, login });
    component.setState(validParams);
    const submitButton = component.find('[type="submit"]').get(0);
    expect(submitButton.props.disabled).toBe(false);
  });

  test('submit button is disabled if state is invalid', () => {
    const login = jest.fn();
    const component = ShallowComponentTester(SignIn, { loading: false, login });
    component.setState({ email: invalidEmail, password: invalidPassword });
    const submitButton = component.find('[type="submit"]').get(0);
    expect(submitButton.props.disabled).toBe(true);
  });
});

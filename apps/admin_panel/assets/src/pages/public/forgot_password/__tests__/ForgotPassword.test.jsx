import Enzyme from 'enzyme';
import Adapter from 'enzyme-adapter-react-16';
import ForgotPassword from '../ForgotPassword';
import ForgotPasswordForm from '../ForgotPasswordForm';
import ForgotPasswordSuccess from '../ForgotPasswordSuccess';
import { ShallowComponentTester } from '../../../../../__tests__/ComponentTester';

Enzyme.configure({ adapter: new Adapter() });

describe('ForgotPassword', () => {
  test('renders ForgotPasswordForm when didReset is false', () => {
    const component = ShallowComponentTester(ForgotPassword);
    expect(component.state('didReset')).toBeFalsy();
    expect(component.find(ForgotPasswordForm).length).toBe(1);
    expect(component.find(ForgotPasswordSuccess).length).toBe(0);
  });

  test('renders ForgotPasswordSuccess when didReset is true', () => {
    const component = ShallowComponentTester(ForgotPassword);
    component.setState({ didReset: true });
    expect(component.state('didReset')).toBeTruthy();
    expect(component.find(ForgotPasswordSuccess).length).toBe(1);
    expect(component.find(ForgotPasswordForm).length).toBe(0);
  });
});

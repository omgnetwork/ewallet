import ResetPassword from '../ResetPassword';
import ResetPasswordForm from '../ResetPasswordForm';
import ResetPasswordSuccess from '../ResetPasswordSuccess';
import { ShallowComponentTester } from '../../../../../__tests__/ComponentTester';

describe('ResetPassword', () => {
  test('renders ResetPasswordForm when didReset is false', () => {
    const component = ShallowComponentTester(ResetPassword);
    expect(component.state('didReset')).toBeFalsy();
    expect(component.find(ResetPasswordForm).length).toBe(1);
    expect(component.find(ResetPasswordSuccess).length).toBe(0);
  });

  test('renders ResetPasswordSuccess when didReset is true', () => {
    const component = ShallowComponentTester(ResetPassword);
    component.setState({ didReset: true });
    expect(component.state('didReset')).toBeTruthy();
    expect(component.find(ResetPasswordSuccess).length).toBe(1);
    expect(component.find(ResetPasswordForm).length).toBe(0);
  });
});

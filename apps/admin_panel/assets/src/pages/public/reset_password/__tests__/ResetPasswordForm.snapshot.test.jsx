import renderer from 'react-test-renderer';
import ResetPasswordForm from '../ResetPasswordForm';
import { SnapshotComponentTester } from '../../../../../__tests__/ComponentTester';

it('renders correctly', () => {
  const resetPassword = jest.fn();
  const onSuccess = jest.fn();
  const tree = renderer.create(SnapshotComponentTester(ResetPasswordForm, {
    loading: false, resetPassword, onSuccess,
  })).toJSON();
  expect(tree).toMatchSnapshot();
});

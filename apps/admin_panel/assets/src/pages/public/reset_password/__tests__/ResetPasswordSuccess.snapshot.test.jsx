import renderer from 'react-test-renderer';
import ResetPasswordSuccess from '../ResetPasswordSuccess';
import { SnapshotComponentTester } from '../../../../../__tests__/ComponentTester';

it('renders correctly', () => {
  const tree =
  renderer.create(SnapshotComponentTester(ResetPasswordSuccess)).toJSON();
  expect(tree).toMatchSnapshot();
});

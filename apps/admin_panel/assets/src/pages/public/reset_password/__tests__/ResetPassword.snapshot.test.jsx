import renderer from 'react-test-renderer';
import ResetPassword from '../ResetPassword';
import { SnapshotComponentTester } from '../../../../../__tests__/ComponentTester';

it('renders correctly', () => {
  const tree = renderer.create(SnapshotComponentTester(ResetPassword, {})).toJSON();
  expect(tree).toMatchSnapshot();
});

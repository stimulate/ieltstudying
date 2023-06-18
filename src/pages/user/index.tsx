import { Link } from 'react-router-dom'
const User = function () {
  return (
    <div>
      <ul>
        <li>
          <Link to="/user/detail/1">用户---1</Link>
        </li>
        <li>
          <Link to="/user/detail/2">用户---2</Link>
        </li>
        <li>
          <Link to="/user/detail/3">用户---3</Link>
        </li>
        <li>
          <Link to="/user/detail/4">用户---4</Link>
        </li>
      </ul>
    </div>
  )
}
export default User

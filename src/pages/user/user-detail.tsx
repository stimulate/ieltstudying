import { useParams } from 'react-router-dom'
const UserDetail = function () {
  const p = useParams()
  return <div>User deatil - {p.id}</div>
}
export default UserDetail

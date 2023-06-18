import { Button } from 'antd'
import { useNavigate } from 'react-router-dom'
const Login = function () {
  const navigate = useNavigate()
  const handleLogin = () => {
    navigate('/')
  }
  return (
    <div>
      <Button onClick={handleLogin}>Login</Button>
    </div>
  )
}
export default Login

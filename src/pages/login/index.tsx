import { Button } from 'antd'
import { useNavigate } from 'react-router-dom'
import { useAppDispatch, useAppSelector } from '../../store/hooks'
import { fetchUserInfoAsync } from '../../store/modules/user'
import { useEffect } from 'react'

const Login = function () {
  const navigate = useNavigate()
  const dispatch = useAppDispatch()
  const user = useAppSelector((state) => state.user)
  const handleLogin = () => {
    dispatch(fetchUserInfoAsync('aa'))
  }
  useEffect(() => {
    if (user.id) {
      navigate('/')
    }
  }, [user.id])
  return (
    <div>
      <h1>{user.status}</h1>
      <Button onClick={handleLogin}>Login</Button>
    </div>
  )
}
export default Login

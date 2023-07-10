import { Button, Input } from 'antd'
import store from '../../store'
import { useNavigate } from 'react-router-dom'
import { fetchUserInfoAsync } from '../../store/action/userAction'
import { useEffect, useState } from 'react'
const Login = function () {
  const navigate = useNavigate()

  useEffect(() => {
    // 监听redux状态值变化，监听到变化时，动态设置appStore的值
    let unsubscribe = store.subscribe(() => {
      const { user } = store.getState()
      if (user?.id) {
        navigate('/')
      }
    })
    // 组件卸载时取消监听
    return () => {
      unsubscribe()
    }
  }, [])

  const handleLogin = () => {
    store.dispatch(fetchUserInfoAsync('01') as any)
  }

  return (
    <div>
      <Input />
      <Button onClick={handleLogin}>Login</Button>
    </div>
  )
}
export default Login

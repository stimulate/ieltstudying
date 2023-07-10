import { useEffect, useState } from 'react'
import { UserStateType } from '../../store/state/userState'
import store from '../../store'

const Menu2 = function () {
  const [userStore, setUserStore] = useState<UserStateType>()
  useEffect(() => {
    // 组件挂载后给appStore初始化值
    const { user } = store.getState()
    setUserStore(user)

    // 监听redux状态值变化，监听到变化时，动态设置appStore的值
    let unsubscribe = store.subscribe(() => {
      const { user } = store.getState()
      setUserStore(user)
    })

    // 组件卸载时取消监听
    return () => {
      unsubscribe()
    }
  }, [])
  return (
    <div>
      <div>Menu2</div>
      <div>id:{userStore?.id}</div>
      <div>name:{userStore?.name}</div>
      <div>age:{userStore?.age}</div>
      <div>phone:{userStore?.phone}</div>
    </div>
  )
}
export default Menu2

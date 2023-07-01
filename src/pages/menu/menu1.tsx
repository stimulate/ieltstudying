import { Button, MenuTheme } from 'antd'
import store from '../../redux'
import reduxAction from '../../redux/action'
import { useEffect, useState } from 'react'
import { UserStateType } from '../../redux/state/userState'
import { AppStateType } from '../../redux/state/appState'

const Menu1 = function () {
  const [userStore, setUserStore] = useState<UserStateType>()
  const [appStore, setAppStore] = useState<AppStateType>()

  useEffect(() => {
    const { user, app } = store.getState()
    setUserStore(user)
    setAppStore(app)

    let unsubscribe = store.subscribe(() => {
      const { app } = store.getState()
      setAppStore(app)
    })

    return () => {
      unsubscribe()
    }
  }, [])

  const handleThemeChange = () => {
    let newThemeName = appStore?.theme === 'dark' ? 'light' : 'dark'
    // 执行redux的action函数，得到含有type类型的对象
    let changeStoreThemeAction = reduxAction.changeStoreTheme(newThemeName)
    // store.dispatch 触发状态变更
    store.dispatch(changeStoreThemeAction)
  }
  return (
    <div>
      <h1>
        当前登录用户是:{userStore?.name},年龄{userStore?.age}
      </h1>
      <Button onClick={handleThemeChange}>
        修改主题为:{appStore?.theme === 'dark' ? '明亮主题' : '暗黑主题'}
      </Button>
    </div>
  )
}
export default Menu1

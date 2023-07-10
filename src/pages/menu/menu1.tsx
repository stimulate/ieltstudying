// const Menu1 = function () {
//   return <div>Menu1</div>
// }
// export default Menu1

import { useEffect, useState } from 'react'
import store from '../../store'
import reduxAction from '../../store/action'
import { AppStateType } from '../../store/state/appState'
import { UserStateType } from '../../store/state/userState'
import { Button } from 'antd'
import { UserAction } from '../../store/action/userAction'

const Menu1 = function () {
  const [appStore, setAppStore] = useState<AppStateType>()
  const [userStore, setUserStore] = useState<UserStateType>()

  useEffect(() => {
    // 组件挂载后给appStore初始化值
    const { user, app } = store.getState()
    setAppStore(app)
    setUserStore(user)

    // 监听redux状态值变化，监听到变化时，动态设置appStore的值
    let unsubscribe = store.subscribe(() => {
      const { app } = store.getState()
      setAppStore(app)
    })

    // 组件卸载时取消监听
    return () => {
      unsubscribe()
    }
  }, [])

  // 处理主题修改按钮点击操作
  const handleThemeChange = () => {
    let newThemeName = appStore?.theme === 'dark' ? 'light' : 'dark'
    // 执行redux的action函数，得到含有type类型的对象
    let changeStoreThemeAction = reduxAction.changeStoreTheme('zgk')
    // store.dispatch 触发状态变更
    store.dispatch(changeStoreThemeAction)
    const { app } = store.getState()

    // const test=():UserAction=>{
    //   return {
    //     type:'',
    //     payload:''
    //   }
    // }
    // store.dispatch(test)
    // store.dispatch({type:"ChangeTheme",payload:newThemeName})
    console.log('appStore?.theme', app.theme)
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

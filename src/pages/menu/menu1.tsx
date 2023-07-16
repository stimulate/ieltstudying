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
import { connect } from 'react-redux'

type Menu1Props = {
  app: AppStateType
  user1: UserStateType
  changeStoreTheme: Function
}

const Menu1 = function ({ app, user1, changeStoreTheme }: Menu1Props) {
  // 处理主题修改按钮点击操作
  const handleThemeChange = () => {
    let newThemeName = app?.theme === 'dark' ? 'light' : 'dark'
    // 执行redux的action函数，得到含有type类型的对象
    let changeStoreThemeAction = reduxAction.changeStoreTheme(newThemeName)
    // store.dispatch 触发状态变更
    // store.dispatch(changeStoreThemeAction)
    changeStoreTheme(changeStoreThemeAction)
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
        当前登录用户是:{user1?.name},年龄{user1?.age}
      </h1>
      <Button onClick={handleThemeChange}>
        修改主题为:{app?.theme === 'dark' ? '明亮主题' : '暗黑主题'}
      </Button>
    </div>
  )
}

// 把store中的state数据作为props绑定到Menu1组件上
const mapStateToProps = (state: Object, ownProp: any) => {
  return state
}

// 把store中将action作为props绑定到Menu1组件上
const mapDispatchToProps = (dispatch: Function, ownProp: any) => {
  return {
    changeStoreTheme: (newThemeName: string) => {
      debugger
      dispatch(reduxAction.changeStoreTheme(newThemeName))
    },
  }
}

export default connect(mapStateToProps, mapDispatchToProps)(Menu1)
// export default Menu1

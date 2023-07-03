import { Button } from 'antd'
import reduxAction from '../../store/action'
import { UserStateType } from '../../store/state/userState'
import { AppStateType } from '../../store/state/appState'
import { connect } from 'react-redux'

type Menu1Props = {
  app: AppStateType
  user: UserStateType
  changeStoreTheme: Function
}

const Menu1 = function ({ app, user, changeStoreTheme }: Menu1Props) {
  const handleThemeChange = () => {
    let newThemeName = app.theme === 'dark' ? 'light' : 'dark'
    changeStoreTheme(newThemeName)
  }
  return (
    <div>
      <h1>
        当前登录用户是:{user?.name},年龄{user?.age}
      </h1>
      <Button onClick={handleThemeChange}>
        修改主题为:{app?.theme === 'dark' ? '明亮主题' : '暗黑主题'}
      </Button>
    </div>
  )
}

// 把store中的state数据作为props绑定到Menu1组件上
const mapStateToProps = (state: Object) => {
  return state
}

// 把store中将action作为props绑定到Menu1组件上
const mapDispatchToProps = (dispatch: Function) => {
  return {
    changeStoreTheme: (newThemeName: string) => {
      dispatch(reduxAction.changeStoreTheme(newThemeName))
    },
  }
}

export default connect(mapStateToProps, mapDispatchToProps)(Menu1)

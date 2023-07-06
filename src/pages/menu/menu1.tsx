import { Button } from 'antd'
import { changeTheme } from '../../store/modules/app'
import { useAppDispatch, useAppSelector } from '../../store/hooks'

const Menu1 = function () {
  const dispatch = useAppDispatch()
  const { app, user } = useAppSelector((state) => state)

  const handleThemeChange = () => {
    let newThemeName = app.theme === 'dark' ? 'light' : 'dark'
    dispatch(changeTheme(newThemeName))
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

export default Menu1

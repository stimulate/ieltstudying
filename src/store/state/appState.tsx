import { MenuTheme } from 'antd/es/menu/MenuContext'

export type AppStateType = {
  title: string
  theme: MenuTheme
}
const appState: AppStateType = {
  title: '应用名称',
  theme: 'dark', //light
}
export default appState

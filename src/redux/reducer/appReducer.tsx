import { Reducer } from 'redux'
import appState, { AppStateType } from '../state/appState'
import { AppAction } from '../action/appAction'
import { MenuTheme } from 'antd/es/menu/MenuContext'

const appReducer: Reducer<AppStateType, AppAction> = (
  state = appState,
  action
) => {
  switch (action.type) {
    case 'ChangeTitle':
      return { ...state, title: action.payload }
    case 'ChangeTheme':
      console.log('appReducer--->app.theme:', action.payload)
      return { ...state, theme: action.payload as MenuTheme }
    default:
      return state
  }
}

export default appReducer

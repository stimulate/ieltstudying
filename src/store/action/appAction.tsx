export type AppAction = {
  type: string
  payload: string
}
function changeStoreTitle(title: string): AppAction {
  return {
    type: 'ChangeTitle',
    payload: title,
  }
}
function changeStoreTheme(theme: string): AppAction {
  return {
    type: 'ChangeTheme',
    payload: theme,
  }
}
export default {
  changeStoreTitle,
  changeStoreTheme,
}

export default defineNuxtPlugin((nuxtApp) => {
  const hasFeature = (feature, forSpecificWorkspace) => true

  nuxtApp.provide('hasFeature', hasFeature)
})

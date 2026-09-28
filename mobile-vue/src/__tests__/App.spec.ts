import { beforeEach, describe, expect, it } from 'vitest'
import { createPinia } from 'pinia'

import { mount } from '@vue/test-utils'
import App from '../App.vue'

describe('App', () => {
  beforeEach(() => window.localStorage.clear())

  it('shows PIN setup before the application shell', () => {
    const wrapper = mount(App, {
      global: {
        plugins: [createPinia()],
        stubs: {
          RouterLink: { template: '<a><slot /></a>' },
          RouterView: { template: '<main />' },
        },
      },
    })

    expect(wrapper.text()).toContain('PFT')
    expect(wrapper.text()).toContain('PIN 설정')
    expect(wrapper.text()).not.toContain('출석 관리')
  })
})

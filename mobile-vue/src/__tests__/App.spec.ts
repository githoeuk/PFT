import { describe, it, expect } from 'vitest'
import { createPinia } from 'pinia'

import { mount } from '@vue/test-utils'
import App from '../App.vue'

describe('App', () => {
  it('renders the PFT application shell', () => {
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
    expect(wrapper.text()).toContain('출석 관리')
  })
})

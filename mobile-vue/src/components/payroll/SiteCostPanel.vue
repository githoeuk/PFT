<script setup lang="ts">
import { computed, nextTick, reactive, ref, watch } from 'vue'
import {
  ChevronDown,
  ChevronUp,
  CircleDollarSign,
  MapPinned,
  Pencil,
  Plus,
  ReceiptText,
  Save,
  Trash2,
  Users,
  X,
} from '@lucide/vue'
import {
  buildSiteCostRows,
  buildSiteLaborRows,
  validateSiteExpense,
} from '@/services/siteCostService'
import { useErpStore } from '@/stores/erp'
import type { SiteExpense, SiteExpenseInput } from '@/types/erp'
import { workerRoleLabels } from '@/utils/erpLabels'
import { formatCurrency, todayIso } from '@/utils/formatters'

const props = defineProps<{ month: string }>()
const emit = defineEmits<{ 'update:month': [month: string] }>()
const store = useErpStore()
const expandedSiteId = ref('')
const detailTab = ref<'labor' | 'expenses'>('labor')
const expenseDay = ref('')
const editorOpen = ref(false)
const editingExpenseId = ref('')
const saving = ref(false)
const errorMessage = ref('')
const message = ref('')
const expenseForm = reactive<SiteExpenseInput>({
  siteId: '',
  date: '',
  description: '',
  amount: 0,
  note: '',
})

const costRows = computed(() =>
  buildSiteCostRows(store.sites, store.attendanceRecords, store.siteExpenses, props.month),
)
const totals = computed(() =>
  costRows.value.reduce(
    (sum, row) => ({
      labor: sum.labor + row.laborCost,
      expenses: sum.expenses + row.expenseCost,
      total: sum.total + row.totalCost,
    }),
    { labor: 0, expenses: 0, total: 0 },
  ),
)
const selectedSite = computed(() =>
  costRows.value.find((row) => row.siteId === expandedSiteId.value),
)
const laborRows = computed(() =>
  buildSiteLaborRows(
    store.attendanceRecords.filter(
      (record) => record.siteId === expandedSiteId.value && record.date.slice(0, 7) === props.month,
    ),
    store.workers,
  ),
)
const expenseRows = computed(() =>
  store.siteExpenses
    .filter(
      (expense) =>
        expense.siteId === expandedSiteId.value &&
        expense.date.slice(0, 7) === props.month &&
        (!expenseDay.value || expense.date === expenseDay.value),
    )
    .sort((a, b) => b.date.localeCompare(a.date) || b.createdAt.localeCompare(a.createdAt)),
)
const visibleExpenseTotal = computed(() =>
  expenseRows.value.reduce((sum, expense) => sum + expense.amount, 0),
)

function closeEditor() {
  editorOpen.value = false
  editingExpenseId.value = ''
}

watch(
  () => props.month,
  () => {
    closeEditor()
    expenseDay.value = ''
    message.value = ''
    errorMessage.value = ''
  },
)

function toggleSite(siteId: string) {
  expandedSiteId.value = expandedSiteId.value === siteId ? '' : siteId
  expenseDay.value = ''
  closeEditor()
}

function openEditor(expense?: SiteExpense) {
  editingExpenseId.value = expense?.id ?? ''
  Object.assign(
    expenseForm,
    expense
      ? {
          siteId: expense.siteId,
          date: expense.date,
          description: expense.description,
          amount: expense.amount,
          note: expense.note,
        }
      : {
          siteId: selectedSite.value?.site?.id ?? store.sites[0]?.id ?? '',
          date:
            expenseDay.value ||
            (todayIso().slice(0, 7) === props.month ? todayIso() : `${props.month}-01`),
          description: '',
          amount: '',
          note: '',
        },
  )
  message.value = ''
  errorMessage.value = ''
  editorOpen.value = true
}

async function saveExpense() {
  if (saving.value) return
  const input = { ...expenseForm, amount: Number(expenseForm.amount) }
  errorMessage.value = validateSiteExpense(input)
  if (errorMessage.value) return
  saving.value = true
  try {
    await store.saveSiteExpense(input, editingExpenseId.value || undefined)
    closeEditor()
    expandedSiteId.value = input.siteId
    detailTab.value = 'expenses'
    expenseDay.value = ''
    emit('update:month', input.date.slice(0, 7))
    await nextTick()
    message.value = '경비를 저장했습니다.'
  } catch {
    errorMessage.value = '경비를 저장하지 못했습니다. 다시 시도해 주세요.'
  } finally {
    saving.value = false
  }
}

async function removeExpense(expense: SiteExpense) {
  if (
    saving.value ||
    !window.confirm(
      `${expense.date} ${expense.description} (${formatCurrency(expense.amount)}) 경비를 삭제하시겠습니까?`,
    )
  )
    return
  saving.value = true
  errorMessage.value = ''
  message.value = ''
  try {
    await store.removeSiteExpense(expense.id)
    if (editingExpenseId.value === expense.id) closeEditor()
    message.value = '경비를 삭제했습니다.'
  } catch {
    errorMessage.value = '경비를 삭제하지 못했습니다. 다시 시도해 주세요.'
  } finally {
    saving.value = false
  }
}

function switchDetailTab(event: KeyboardEvent) {
  if (!['ArrowLeft', 'ArrowRight', 'Home', 'End'].includes(event.key)) return
  event.preventDefault()
  detailTab.value =
    event.key === 'Home'
      ? 'labor'
      : event.key === 'End'
        ? 'expenses'
        : detailTab.value === 'labor'
          ? 'expenses'
          : 'labor'
  document.getElementById(`cost-tab-${detailTab.value}`)?.focus()
}
</script>

<template>
  <section class="metric-grid" aria-label="현장 원가 요약">
    <article class="metric-item">
      <span class="metric-icon blue"><MapPinned :size="20" /></span>
      <div>
        <small>등록 현장</small><strong>{{ store.sites.length }}</strong>
      </div>
    </article>
    <article class="metric-item">
      <span class="metric-icon green"><Users :size="20" /></span>
      <div>
        <small>인건비</small><strong class="money-value">{{ formatCurrency(totals.labor) }}</strong>
      </div>
    </article>
    <article class="metric-item">
      <span class="metric-icon amber"><ReceiptText :size="20" /></span>
      <div>
        <small>기타 경비</small
        ><strong class="money-value">{{ formatCurrency(totals.expenses) }}</strong>
      </div>
    </article>
    <article class="metric-item">
      <span class="metric-icon red"><CircleDollarSign :size="20" /></span>
      <div>
        <small>총비용</small><strong class="money-value">{{ formatCurrency(totals.total) }}</strong>
      </div>
    </article>
  </section>

  <div class="section-heading cost-heading">
    <div>
      <h2>현장별 원가</h2>
      <p>{{ month || '선택된 월 없음' }}</p>
    </div>
    <button
      class="button button-primary"
      type="button"
      :disabled="!store.sites.length || !month || saving"
      @click="openEditor()"
    >
      <Plus :size="17" />경비 추가
    </button>
  </div>
  <p v-if="message" class="cost-message" role="status">{{ message }}</p>
  <p v-if="errorMessage" class="cost-message form-message-error" role="alert">{{ errorMessage }}</p>

  <form
    v-if="editorOpen"
    class="editor-panel expense-editor"
    aria-label="경비 입력"
    @submit.prevent="saveExpense"
  >
    <div class="section-heading editor-heading">
      <h2>{{ editingExpenseId ? '경비 수정' : '경비 등록' }}</h2>
      <button
        class="icon-button"
        title="경비 입력 닫기"
        type="button"
        :disabled="saving"
        @click="closeEditor"
      >
        <X :size="17" />
      </button>
    </div>
    <fieldset :disabled="saving" class="form-grid">
      <label
        ><span>현장</span
        ><select v-model="expenseForm.siteId" required>
          <option v-for="site in store.sites" :key="site.id" :value="site.id">
            {{ site.name }}
          </option>
        </select></label
      >
      <label><span>날짜</span><input v-model="expenseForm.date" type="date" required /></label>
      <label
        ><span>경비 내용</span
        ><input
          v-model="expenseForm.description"
          type="text"
          maxlength="120"
          required
          placeholder="점심 식사, 간식, 주차비 등"
      /></label>
      <label
        ><span>금액 (원)</span
        ><input
          v-model.number="expenseForm.amount"
          type="number"
          min="1"
          step="1"
          inputmode="numeric"
          required
      /></label>
      <label class="span-2"
        ><span>비고</span><textarea v-model="expenseForm.note" rows="2" maxlength="500" />
      </label>
    </fieldset>
    <div class="form-actions">
      <button class="button button-secondary" type="button" :disabled="saving" @click="closeEditor">
        <X :size="15" />취소
      </button>
      <button class="button button-primary" type="submit" :disabled="saving">
        <Save :size="15" />{{ saving ? '저장 중...' : '저장' }}
      </button>
    </div>
  </form>

  <div v-if="costRows.length" class="data-table-wrap cost-table-wrap">
    <table class="data-table management-table cost-table" aria-label="현장별 원가">
      <thead>
        <tr>
          <th>현장</th>
          <th>인건비</th>
          <th>기타 경비</th>
          <th>총비용</th>
          <th aria-label="상세"></th>
        </tr>
      </thead>
      <tbody>
        <tr
          v-for="row in costRows"
          :key="row.siteId"
          :class="{ 'selected-cost-row': expandedSiteId === row.siteId }"
        >
          <td data-label="현장">
            <strong>{{ row.siteName }}</strong
            ><small>{{ row.workedDays }}일 · 경비 {{ row.expenseCount }}건</small>
          </td>
          <td data-label="인건비">{{ formatCurrency(row.laborCost) }}</td>
          <td data-label="기타 경비">{{ formatCurrency(row.expenseCost) }}</td>
          <td data-label="총비용">
            <strong>{{ formatCurrency(row.totalCost) }}</strong>
          </td>
          <td class="table-actions-cell" data-label="상세">
            <div class="table-actions">
              <button
                class="icon-button"
                type="button"
                :title="`${row.siteName} 정산 ${expandedSiteId === row.siteId ? '접기' : '펼치기'}`"
                :aria-expanded="expandedSiteId === row.siteId"
                aria-controls="site-cost-details"
                :disabled="saving"
                @click="toggleSite(row.siteId)"
              >
                <ChevronUp v-if="expandedSiteId === row.siteId" :size="17" /><ChevronDown
                  v-else
                  :size="17"
                />
              </button>
            </div>
          </td>
        </tr>
      </tbody>
      <tfoot>
        <tr>
          <th>합계</th>
          <td>{{ formatCurrency(totals.labor) }}</td>
          <td>{{ formatCurrency(totals.expenses) }}</td>
          <td>
            <strong>{{ formatCurrency(totals.total) }}</strong>
          </td>
          <td></td>
        </tr>
      </tfoot>
    </table>
  </div>
  <div v-else class="empty-state">
    <MapPinned :size="28" /><strong>등록된 현장이 없습니다</strong
    ><RouterLink class="button button-secondary" to="/sites">현장 관리</RouterLink>
  </div>

  <section
    v-if="selectedSite"
    id="site-cost-details"
    class="site-cost-details"
    :aria-label="`${selectedSite.siteName} 정산 상세`"
  >
    <div class="section-heading cost-heading">
      <div>
        <h2>{{ selectedSite.siteName }}</h2>
        <p>{{ month }} · 총비용 {{ formatCurrency(selectedSite.totalCost) }}</p>
      </div>
    </div>
    <div
      class="payroll-tabs cost-detail-tabs"
      role="tablist"
      aria-label="현장 비용 구분"
      @keydown="switchDetailTab"
    >
      <button
        id="cost-tab-labor"
        type="button"
        role="tab"
        :aria-selected="detailTab === 'labor'"
        aria-controls="cost-panel-labor"
        :tabindex="detailTab === 'labor' ? 0 : -1"
        @click="detailTab = 'labor'"
      >
        <Users :size="16" />인건비
      </button>
      <button
        id="cost-tab-expenses"
        type="button"
        role="tab"
        :aria-selected="detailTab === 'expenses'"
        aria-controls="cost-panel-expenses"
        :tabindex="detailTab === 'expenses' ? 0 : -1"
        @click="detailTab = 'expenses'"
      >
        <ReceiptText :size="16" />기타 경비
      </button>
    </div>
    <div
      id="cost-panel-labor"
      v-show="detailTab === 'labor'"
      role="tabpanel"
      aria-labelledby="cost-tab-labor"
    >
      <div v-if="laborRows.length" class="data-table-wrap">
        <table class="data-table" aria-label="현장 근로자별 인건비">
          <thead>
            <tr>
              <th>근로자</th>
              <th>직책</th>
              <th>작업일</th>
              <th>연장시간</th>
              <th>적용 일급</th>
              <th>인건비</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="row in laborRows" :key="row.workerId">
              <td>{{ row.workerName }}</td>
              <td>{{ row.roles.map((role) => workerRoleLabels[role]).join(', ') }}</td>
              <td>{{ row.workedDays }}일</td>
              <td>{{ row.overtimeHours }}시간</td>
              <td>
                {{ formatCurrency(row.minimumRate)
                }}<template v-if="row.minimumRate !== row.maximumRate">
                  ~ {{ formatCurrency(row.maximumRate) }}</template
                >
              </td>
              <td>
                <strong>{{ formatCurrency(row.laborCost) }}</strong>
              </td>
            </tr>
          </tbody>
          <tfoot>
            <tr>
              <th colspan="5">인건비 합계</th>
              <td>
                <strong>{{ formatCurrency(selectedSite.laborCost) }}</strong>
              </td>
            </tr>
          </tfoot>
        </table>
      </div>
      <div v-else class="empty-state">
        <Users :size="26" /><strong>선택한 월의 근무 기록이 없습니다</strong>
      </div>
    </div>
    <div
      id="cost-panel-expenses"
      v-show="detailTab === 'expenses'"
      role="tabpanel"
      aria-labelledby="cost-tab-expenses"
    >
      <div class="expense-toolbar">
        <label
          ><span>경비 날짜</span><input v-model="expenseDay" type="date" :min="`${month}-01`"
        /></label>
        <button
          class="icon-button"
          title="날짜 필터 초기화"
          type="button"
          :disabled="!expenseDay"
          @click="expenseDay = ''"
        >
          <X :size="16" />
        </button>
        <strong>{{ expenseRows.length }}건 · {{ formatCurrency(visibleExpenseTotal) }}</strong>
      </div>
      <div v-if="expenseRows.length" class="data-table-wrap">
        <table class="data-table management-table expense-table" aria-label="현장 기타 경비">
          <thead>
            <tr>
              <th>경비 내용</th>
              <th>날짜</th>
              <th>금액</th>
              <th>비고</th>
              <th aria-label="관리"></th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="expense in expenseRows" :key="expense.id">
              <td data-label="경비 내용">
                <strong>{{ expense.description }}</strong>
              </td>
              <td data-label="날짜">{{ expense.date }}</td>
              <td data-label="금액">
                <strong>{{ formatCurrency(expense.amount) }}</strong>
              </td>
              <td class="expense-note" data-label="비고">{{ expense.note || '-' }}</td>
              <td class="table-actions-cell" data-label="관리">
                <div class="table-actions">
                  <button
                    class="icon-button"
                    title="경비 수정"
                    type="button"
                    :disabled="saving"
                    @click="openEditor(expense)"
                  >
                    <Pencil :size="16" /></button
                  ><button
                    class="icon-button danger-button"
                    title="경비 삭제"
                    type="button"
                    :disabled="saving"
                    @click="removeExpense(expense)"
                  >
                    <Trash2 :size="16" />
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <div v-else class="empty-state">
        <ReceiptText :size="26" /><strong>선택한 기간의 경비가 없습니다</strong>
      </div>
    </div>
  </section>
</template>

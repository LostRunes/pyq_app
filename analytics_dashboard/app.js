// Supabase Connection Credentials (from production configuration)
const SUPABASE_URL = 'https://bjmrsrypznobolwumjhe.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJqbXJzcnlwem5vYm9sd3VtamhlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAyMTk4MDAsImV4cCI6MjA5NTc5NTgwMH0.1IY2A8bTDbexuJYiM14dZyN80OrDUkFbzeupjEJLXqs';

// Global App State
let supabaseClient = null;
let allEvents = [];
let filteredEvents = [];
let currentPage = 1;
const pageSize = 10;

// Chart Instances
let timelineChart = null;
let featuresChart = null;

// DOM Elements
const elBody = document.getElementById('events-table-body');
const elTotalEvents = document.getElementById('stat-total-events');
const elActiveUsers = document.getElementById('stat-active-users');
const elTopFeature = document.getElementById('stat-top-feature');
const elDbSplit = document.getElementById('stat-db-split');
const elSearchInput = document.getElementById('search-input');
const elFilterType = document.getElementById('filter-event-type');
const elFilterSource = document.getElementById('filter-source');
const elBtnRefresh = document.getElementById('btn-refresh');
const elBtnExport = document.getElementById('btn-export');
const elBtnPrev = document.getElementById('btn-prev');
const elBtnNext = document.getElementById('btn-next');
const elPaginationPages = document.getElementById('pagination-pages');
const elSpanStartRow = document.getElementById('span-start-row');
const elSpanEndRow = document.getElementById('span-end-row');
const elSpanTotalRows = document.getElementById('span-total-rows');
const elConnectionStatus = document.getElementById('connection-status');

// Modal Elements
const elModal = document.getElementById('metadata-modal');
const elModalClose = document.getElementById('btn-close-modal');
const elModalCode = document.getElementById('metadata-json-code');

// Initialize the dashboard
document.addEventListener('DOMContentLoaded', () => {
  initSupabase();
  setupEventListeners();
  fetchData();
});

// Configure client connection
function initSupabase() {
  try {
    supabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
    updateStatus('connected', '<i class="fa-solid fa-circle-check"></i> Connected');
  } catch (error) {
    console.error('Supabase initialization failed:', error);
    updateStatus('disconnected', '<i class="fa-solid fa-circle-xmark"></i> Connection Error');
  }
}

// Update the UI status badge
function updateStatus(status, htmlContent) {
  elConnectionStatus.className = `status-badge status-${status}`;
  elConnectionStatus.innerHTML = htmlContent;
}

// Setup all event listeners
function setupEventListeners() {
  elBtnRefresh.addEventListener('click', fetchData);
  elBtnExport.addEventListener('click', exportToCSV);
  
  elSearchInput.addEventListener('input', () => {
    currentPage = 1;
    filterAndRender();
  });
  
  elFilterType.addEventListener('change', () => {
    currentPage = 1;
    filterAndRender();
  });
  
  elFilterSource.addEventListener('change', () => {
    currentPage = 1;
    filterAndRender();
  });

  elBtnPrev.addEventListener('click', () => {
    if (currentPage > 1) {
      currentPage--;
      renderTable();
    }
  });

  elBtnNext.addEventListener('click', () => {
    const totalPages = Math.ceil(filteredEvents.length / pageSize);
    if (currentPage < totalPages) {
      currentPage++;
      renderTable();
    }
  });

  // Modal events
  elModalClose.addEventListener('click', () => {
    elModal.style.display = 'none';
  });

  window.addEventListener('click', (event) => {
    if (event.target === elModal) {
      elModal.style.display = 'none';
    }
  });
}

// Fetch unified data (Supabase first, then Neon DB in background)
async function fetchData() {
  if (!supabaseClient) return;
  
  updateStatus('loading', '<i class="fa-solid fa-circle-notch fa-spin"></i> Fetching active logs...');
  elBody.innerHTML = `
    <tr>
      <td colspan="7" class="loading-placeholder">
        <i class="fa-solid fa-spinner fa-spin"></i> Fetching active analytics events...
      </td>
    </tr>
  `;
  
  try {
    // 1. Fetch from local Supabase events (instant)
    const { data, error } = await supabaseClient
      .from('v_supabase_analytics')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(1000);

    if (error) throw error;

    allEvents = data || [];
    filteredEvents = [...allEvents];
    currentPage = 1;

    updateStatus('connected', '<i class="fa-solid fa-circle-check"></i> Connected (Supabase Only)');
    filterAndRender();

    // 2. Fetch Neon DB logs in the background asynchronously
    fetchNeonData();
  } catch (error) {
    console.error('Error fetching Supabase data:', error);
    const errorMsg = error.message || (typeof error === 'object' ? JSON.stringify(error) : error);
    updateStatus('disconnected', `<i class="fa-solid fa-triangle-exclamation"></i> Fetch Failed`);
    elBody.innerHTML = `
      <tr>
        <td colspan="7" class="loading-placeholder" style="color: #F44336;">
          <i class="fa-solid fa-circle-xmark"></i> Failed to retrieve analytics.<br>
          <span style="font-size: 12px; font-family: monospace; opacity: 0.8;">Details: ${errorMsg}</span>
        </td>
      </tr>
    `;
  }
}

// Asynchronously fetch Neon DB events and merge them
async function fetchNeonData() {
  try {
    updateStatus('loading', '<i class="fa-solid fa-circle-notch fa-spin"></i> Loading Neon DB Archives...');
    
    const { data: neonData, error } = await supabaseClient
      .from('v_neon_analytics')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(1000);

    if (error) throw error;

    if (neonData && neonData.length > 0) {
      // Merge events, keeping only unique records
      const existingIds = new Set(allEvents.map(e => e.id));
      const uniqueNeon = neonData.filter(e => !existingIds.has(e.id));
      
      allEvents = [...allEvents, ...uniqueNeon];
      
      // Sort combined array descending by date
      allEvents.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
      
      filterAndRender();
    }
    
    updateStatus('connected', '<i class="fa-solid fa-circle-check"></i> Connected');
  } catch (error) {
    console.warn('Neon DB background fetch failed/timed out (expected on cold start):', error);
    updateStatus('connected', '<i class="fa-solid fa-circle-check"></i> Connected (Neon Offline/Waking)');
  }
}

// Perform client-side filter, search and update charts + table
function filterAndRender() {
  const searchQuery = elSearchInput.value.toLowerCase().trim();
  const selectedType = elFilterType.value;
  const selectedSource = elFilterSource.value;

  filteredEvents = allEvents.filter(event => {
    // 1. Search Query mapping
    const matchSearch = !searchQuery || 
      (event.event_name && event.event_name.toLowerCase().includes(searchQuery)) ||
      (event.event_type && event.event_type.toLowerCase().includes(searchQuery)) ||
      (event.screen_name && event.screen_name.toLowerCase().includes(searchQuery)) ||
      (event.username && event.username.toLowerCase().includes(searchQuery)) ||
      (event.display_name && event.display_name.toLowerCase().includes(searchQuery)) ||
      (event.email && event.email.toLowerCase().includes(searchQuery));

    // 2. Type Filter
    const matchType = selectedType === 'all' || event.event_type === selectedType;

    // 3. Source Filter
    const matchSource = selectedSource === 'all' || event.source === selectedSource;

    return matchSearch && matchType && matchSource;
  });

  updateStats();
  updateCharts();
  renderTable();
}

// Calculate summary stats
function updateStats() {
  // 1. Total events
  elTotalEvents.innerText = filteredEvents.length.toLocaleString();

  // 2. Active users
  const uniqueUsers = new Set();
  filteredEvents.forEach(e => {
    if (e.user_id) uniqueUsers.add(e.user_id);
  });
  elActiveUsers.innerText = uniqueUsers.size.toLocaleString();

  // 3. Most used feature
  const featureCounts = {};
  filteredEvents.forEach(e => {
    if (e.event_name) {
      featureCounts[e.event_name] = (featureCounts[e.event_name] || 0) + 1;
    }
  });
  
  let topFeature = 'None';
  let maxCount = 0;
  for (const [feat, count] of Object.entries(featureCounts)) {
    if (count > maxCount) {
      maxCount = count;
      topFeature = feat;
    }
  }
  elTopFeature.innerText = topFeature.replaceAll('_', ' ');

  // 4. DB source split
  let supabaseCount = 0;
  let neonCount = 0;
  filteredEvents.forEach(e => {
    if (e.source === 'supabase') supabaseCount++;
    else if (e.source === 'neon') neonCount++;
  });
  elDbSplit.innerHTML = `<span style="color: var(--neon-color);">${neonCount}</span> / <span style="color: var(--primary-color);">${supabaseCount}</span>`;
}

// Render dynamic charts
function updateCharts() {
  // --- 1. Timeline Chart (Events over time) ---
  const dailyData = {};
  filteredEvents.forEach(e => {
    if (e.created_at) {
      const dateStr = new Date(e.created_at).toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
      dailyData[dateStr] = (dailyData[dateStr] || 0) + 1;
    }
  });

  // Sort daily dates (reverse of created_at desc order)
  const timelineLabels = Object.keys(dailyData).reverse();
  const timelineValues = timelineLabels.map(label => dailyData[label]);

  if (timelineChart) timelineChart.destroy();
  
  const ctxTimeline = document.getElementById('timelineChart').getContext('2d');
  
  // Custom orange gradient for background
  const gradientOrange = ctxTimeline.createLinearGradient(0, 0, 0, 300);
  gradientOrange.addColorStop(0, 'rgba(255, 159, 10, 0.4)');
  gradientOrange.addColorStop(1, 'rgba(255, 159, 10, 0.0)');

  timelineChart = new Chart(ctxTimeline, {
    type: 'line',
    data: {
      labels: timelineLabels.slice(-10), // Limit to last 10 days for clarity
      datasets: [{
        label: 'Event Count',
        data: timelineValues.slice(-10),
        borderColor: '#FF9F0A',
        borderWidth: 3,
        pointBackgroundColor: '#FF9F0A',
        pointBorderColor: '#FFFFFF',
        pointBorderWidth: 1.5,
        pointRadius: 4,
        pointHoverRadius: 6,
        backgroundColor: gradientOrange,
        fill: true,
        tension: 0.3
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { display: false }
      },
      scales: {
        x: {
          grid: { display: false },
          ticks: { color: '#A0A5C0', font: { family: 'Outfit' } }
        },
        y: {
          grid: { color: 'rgba(255, 255, 255, 0.05)' },
          ticks: { color: '#A0A5C0', font: { family: 'Outfit' } }
        }
      }
    }
  });

  // --- 2. Feature Type Distribution (Doughnut) ---
  const typeCounts = {
    'feature_use': 0,
    'page_entry': 0,
    'page_view': 0,
    'auth': 0,
    'app_lifecycle': 0,
    'other': 0
  };

  filteredEvents.forEach(e => {
    if (e.event_type in typeCounts) {
      typeCounts[e.event_type]++;
    } else {
      typeCounts['other']++;
    }
  });

  const doughnutLabels = ['Feature Use', 'Page Entry', 'Page View', 'Auth', 'Lifecycle', 'Other'];
  const doughnutValues = [
    typeCounts['feature_use'],
    typeCounts['page_entry'],
    typeCounts['page_view'],
    typeCounts['auth'],
    typeCounts['app_lifecycle'],
    typeCounts['other']
  ];

  if (featuresChart) featuresChart.destroy();
  
  const ctxFeatures = document.getElementById('featuresChart').getContext('2d');
  featuresChart = new Chart(ctxFeatures, {
    type: 'doughnut',
    data: {
      labels: doughnutLabels,
      datasets: [{
        data: doughnutValues,
        backgroundColor: [
          '#B388FF', // purple
          '#80CBC4', // teal
          '#90CAF9', // blue
          '#A5D6A7', // green
          '#F48FB1', // pink
          '#6C7085'  /* grey */
        ],
        borderWidth: 0,
        hoverOffset: 4
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          position: 'right',
          labels: {
            color: '#A0A5C0',
            font: { family: 'Outfit', size: 11 },
            boxWidth: 12,
            padding: 10
          }
        }
      },
      cutout: '65%'
    }
  });
}

// Render data table with paginated data
function renderTable() {
  const startIdx = (currentPage - 1) * pageSize;
  const endIdx = startIdx + pageSize;
  const pageItems = filteredEvents.slice(startIdx, endIdx);

  // Update Footer Counters
  elSpanTotalRows.innerText = filteredEvents.length;
  elSpanStartRow.innerText = filteredEvents.length === 0 ? 0 : startIdx + 1;
  elSpanEndRow.innerText = Math.min(endIdx, filteredEvents.length);

  if (pageItems.length === 0) {
    elBody.innerHTML = `
      <tr>
        <td colspan="7" class="loading-placeholder">
          <i class="fa-solid fa-magnifying-glass"></i> No events match your filters and search.
        </td>
      </tr>
    `;
    updatePaginationControls(0);
    return;
  }

  let html = '';
  pageItems.forEach(e => {
    // 1. Date conversion
    const localDate = e.created_at 
      ? new Date(e.created_at).toLocaleString() 
      : '-';

    // 2. User display details
    const uName = e.username || 'anonymous';
    const dName = e.display_name || 'Guest User';
    const email = e.email || 'no-email@session';
    const avatarLetter = (e.display_name || 'U').charAt(0).toUpperCase();

    // 3. Badges mapping
    const typeClass = `badge-type-${(e.event_type || 'other').replace('_', '').replace('view', 'page').replace('entry', 'page')}`;
    const cleanType = (e.event_type || 'other').replaceAll('_', ' ');

    const sourceClass = `badge-source-${e.source}`;
    const cleanSource = e.source === 'supabase' ? 'Supabase' : 'Neon DB';

    // 4. Row rendering
    html += `
      <tr>
        <td style="white-space: nowrap; font-weight: 500;">${localDate}</td>
        <td>
          <div class="user-info-cell">
            <div class="user-avatar">${avatarLetter}</div>
            <div class="user-text">
              <span class="user-name">${dName} <small style="color: var(--text-dark); font-weight: 500;">(@${uName})</small></span>
              <span class="user-email">${email}</span>
            </div>
          </div>
        </td>
        <td><span class="badge ${typeClass}">${cleanType}</span></td>
        <td style="font-family: monospace; font-weight: 600; color: #E91E63;">${e.event_name || '-'}</td>
        <td style="color: var(--text-muted); font-family: monospace;">${e.screen_name || '-'}</td>
        <td><span class="badge ${sourceClass}">${cleanSource}</span></td>
        <td>
          <button class="btn-action" onclick="showMetadataModal('${escapeHtml(JSON.stringify(e.metadata || {}))}')">
            <i class="fa-solid fa-code"></i> View JSON
          </button>
        </td>
      </tr>
    `;
  });

  elBody.innerHTML = html;
  
  const totalPages = Math.ceil(filteredEvents.length / pageSize);
  updatePaginationControls(totalPages);
}

// Manage pagination elements
function updatePaginationControls(totalPages) {
  elBtnPrev.disabled = currentPage === 1;
  elBtnNext.disabled = currentPage >= totalPages || totalPages === 0;

  let pagesHtml = '';
  const maxButtons = 5;
  let startPage = Math.max(1, currentPage - 2);
  let endPage = Math.min(totalPages, startPage + maxButtons - 1);

  if (endPage - startPage < maxButtons - 1) {
    startPage = Math.max(1, endPage - maxButtons + 1);
  }

  for (let i = startPage; i <= endPage; i++) {
    pagesHtml += `
      <div class="page-num ${i === currentPage ? 'active' : ''}" onclick="goToPage(${i})">
        ${i}
      </div>
    `;
  }

  elPaginationPages.innerHTML = pagesHtml;
}

function goToPage(page) {
  currentPage = page;
  renderTable();
}

// Display Metadata Modal dialog
window.showMetadataModal = function(metadataJsonStr) {
  try {
    const rawObj = JSON.parse(metadataJsonStr);
    const prettyJson = JSON.stringify(rawObj, null, 2);
    elModalCode.innerText = prettyJson;
    elModal.style.display = 'block';
  } catch (err) {
    elModalCode.innerText = '{}';
    elModal.style.display = 'block';
  }
};

// Export records as CSV download
function exportToCSV() {
  if (filteredEvents.length === 0) return;
  
  const headers = ['id', 'user_id', 'username', 'display_name', 'email', 'event_type', 'event_name', 'screen_name', 'source', 'created_at', 'metadata'];
  
  const csvRows = [
    headers.join(','),
    ...filteredEvents.map(e => {
      return headers.map(header => {
        let val = e[header];
        if (header === 'metadata') {
          val = JSON.stringify(val || {});
        }
        // Escape quotes
        const escaped = ('' + (val ?? '')).replace(/"/g, '""');
        return `"${escaped}"`;
      }).join(',');
    })
  ];

  const csvContent = 'data:text/csv;charset=utf-8,' + csvRows.join('\n');
  const encodedUri = encodeURI(csvContent);
  const link = document.createElement('a');
  link.setAttribute('href', encodedUri);
  link.setAttribute('download', `focus_fox_analytics_${new Date().toISOString().split('T')[0]}.csv`);
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
}

// Helper to escape HTML characters
function escapeHtml(text) {
  return text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}
